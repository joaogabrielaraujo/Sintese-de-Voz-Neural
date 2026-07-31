import 'dart:async';
import 'dart:io';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import '../text/tts_normalizer.dart';
import 'tts_engine_interface.dart';

/// Motor de Inferência Neural VITS ONNX Real usando a biblioteca C++ `sherpa_onnx` via FFI.
///
/// Carrega o modelo `pt_BR-faber-medium.onnx` e o dicionário `tokens.txt` para gerar
/// a voz humana exata do locutor Faber com síntese neural HiFi-GAN em tempo real.
///
/// Para modelos VITS baseados em caracteres (como Piper Faber PT-BR), o parâmetro
/// `lexicon` é forçado como string vazia `""`, fazendo a C++ converter os caracteres
/// diretamente via `tokens.txt`, eliminando erros OOV e dependências de dicionários externos.
class SherpaOnnxTTSEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  sherpa.OfflineTts? _tts;
  DynamicLibrary? _onnxRuntimeLibrary;
  bool _initialized = false;

  /// Trava assíncrona para garantir execução sequencial e thread-safe na C++
  Completer<void>? _synthesisLock;

  SherpaOnnxTTSEngine({TTSConfig? config})
      : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized && _tts != null;

  @override
  Future<void> initialize() async {
    if (_initialized && _tts != null) return;

    try {
      // 1. Obter diretório de armazenamento local do aplicativo com fallback de segurança (Android/iOS/Desktop)
      Directory baseDir;
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        try {
          baseDir = await getTemporaryDirectory();
        } catch (_) {
          baseDir = Directory.current;
        }
      }
      final Directory modelDir = Directory(p.join(baseDir.path, 'models'));
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // 2. Extrair e verificar integridade de tamanho dos arquivos em assets/models/
      final String rawModelPath = p.join(
        modelDir.path,
        'pt_BR-faber-medium.onnx',
      );
      final String rawTokensPath = p.join(modelDir.path, 'tokens.txt');
      await _copyAssetToFileWithValidation(config.modelPath, rawModelPath);
      await _copyAssetToFileWithValidation(config.tokensPath, rawTokensPath);

      // Resolução estrita de caminhos absolutos para a biblioteca C++ nativa
      final String absModelPath = await _validateAndGetAbsolutePath(
        rawModelPath,
      );
      final String absTokensPath = await _validateAndGetAbsolutePath(
        rawTokensPath,
      );
      final String absEspeakDataDir = await _prepareEspeakDataDirectory(
        modelDir,
      );

      // 3. Windows precisa carregar o ONNX Runtime por caminho absoluto antes
      // de abrir a DLL Sherpa; isso evita o erro 193 quando a busca implícita
      // resolve uma DLL incompatível em outro diretório.
      _preloadOnnxRuntime();

      // 4. Configurar a engine C++ Sherpa-ONNX com tratamento FFI seguro.
      sherpa.initBindings();

      final vitsConfig = sherpa.OfflineTtsVitsModelConfig(
        model: absModelPath,
        tokens: absTokensPath,
        lexicon: '',
        dataDir: absEspeakDataDir,
        noiseScale: config.noiseScale,
        noiseScaleW: 0.8,
        lengthScale: config.lengthScale,
      );

      final modelConfig = sherpa.OfflineTtsModelConfig(
        vits: vitsConfig,
        numThreads: config.numThreads,
        debug: false,
        provider: 'cpu',
      );

      final ttsConfig = sherpa.OfflineTtsConfig(model: modelConfig);

      _tts = sherpa.OfflineTts(ttsConfig);
      _initialized = true;
      debugPrint(
        '[SherpaOnnxTTSEngine FFI] Inicializado com sucesso em $absModelPath!',
      );
    } catch (e, stack) {
      debugPrint(
        '[SherpaOnnxTTSEngine FFI] Erro ao inicializar engine ONNX C++: $e\n$stack',
      );
      _initialized = false;
      _tts = null;
      Error.throwWithStackTrace(
        TTSEngineInitializationException(
          'Could not initialize Sherpa-ONNX. Check model, tokens, native runtime, and espeakDataPath.',
          e,
        ),
        stack,
      );
    }
  }

  void _preloadOnnxRuntime() {
    if (!Platform.isWindows || _onnxRuntimeLibrary != null) return;

    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      p.join(executableDirectory, 'onnxruntime.dll'),
      p.join(Directory.current.path, 'onnxruntime.dll'),
    ];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        _onnxRuntimeLibrary = DynamicLibrary.open(candidate);
        return;
      }
    }

    // Preserve the package's normal loader behavior when running in an
    // environment that supplies native libraries through PATH.
    _onnxRuntimeLibrary = DynamicLibrary.open('onnxruntime.dll');
  }

  Future<String> _prepareEspeakDataDirectory(Directory modelDir) async {
    final configuredPath = config.espeakDataPath?.trim();
    if (configuredPath == null || configuredPath.isEmpty) {
      throw const TTSEngineInitializationException(
        'This Piper voice requires a complete espeak-ng-data directory. Configure TTSConfig.espeakDataPath.',
      );
    }

    final configuredDirectory = Directory(configuredPath).absolute;
    if (await configuredDirectory.exists()) {
      return _validateEspeakDataDirectory(configuredDirectory);
    }

    if (!configuredPath.startsWith('assets/')) {
      throw FileSystemException(
        'espeak-ng-data directory was not found',
        configuredDirectory.path,
      );
    }

    final directory = Directory(p.join(modelDir.path, 'espeak-ng-data'));
    await _copyAssetDirectoryWithValidation(configuredPath, directory);
    return _validateEspeakDataDirectory(directory);
  }

  Future<String> _validateEspeakDataDirectory(Directory directory) async {
    if (!await directory.exists()) {
      throw FileSystemException(
        'espeak-ng-data directory was not found',
        directory.path,
      );
    }
    if (await directory.list(followLinks: false).isEmpty) {
      throw FileSystemException(
        'espeak-ng-data directory is empty',
        directory.path,
      );
    }
    for (final requiredFile in const <String>['phondata', 'phontab']) {
      if (!await File(p.join(directory.path, requiredFile)).exists()) {
        throw FileSystemException(
          'espeak-ng-data is incomplete; missing $requiredFile',
          directory.path,
        );
      }
    }
    return directory.path;
  }

  Future<void> _copyAssetDirectoryWithValidation(
    String assetPrefix,
    Directory targetDirectory,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final prefix = assetPrefix.endsWith('/') ? assetPrefix : '$assetPrefix/';
    final assetPaths = manifest
        .listAssets()
        .where((asset) => asset.startsWith(prefix))
        .toList(growable: false);

    if (assetPaths.isEmpty) {
      throw FileSystemException(
        'No bundled assets found for espeak-ng-data',
        assetPrefix,
      );
    }

    for (final assetPath in assetPaths) {
      final relativePath = assetPath.substring(prefix.length);
      if (relativePath.isEmpty || relativePath.contains('..')) {
        throw FileSystemException(
          'Invalid relative path in espeak-ng-data asset manifest',
          assetPath,
        );
      }

      final targetFile = File(p.join(targetDirectory.path, relativePath));
      final data = await rootBundle.load(assetPath);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      if (!await targetFile.exists() ||
          await targetFile.length() != data.lengthInBytes) {
        await targetFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }
    }
  }

  /// Valida a existência, tamanho e converte o caminho para um caminho absoluto válido.
  Future<String> _validateAndGetAbsolutePath(String filePath) async {
    final file = File(filePath).absolute;
    if (!await file.exists()) {
      throw FileSystemException(
        'Arquivo necessário para inferência ONNX não encontrado',
        file.path,
      );
    }
    if (await file.length() == 0) {
      throw FileSystemException(
        'Arquivo de modelo ONNX / tokens encontra-se corrompido ou vazio (0 bytes)',
        file.path,
      );
    }
    return file.path;
  }

  Future<void> _copyAssetToFileWithValidation(
    String assetPath,
    String targetFilePath,
  ) async {
    final File targetFile = File(targetFilePath);

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final int expectedLength = data.lengthInBytes;

      if (!await targetFile.exists() ||
          (await targetFile.length()) != expectedLength) {
        if (!await targetFile.parent.exists()) {
          await targetFile.parent.create(recursive: true);
        }
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await targetFile.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      debugPrint(
        '[SherpaOnnxTTSEngine] Aviso ao carregar asset via rootBundle "$assetPath": $e',
      );
      final File assetFile = File(assetPath);
      if (await assetFile.exists()) {
        final int expectedLength = await assetFile.length();
        if (!await targetFile.exists() ||
            (await targetFile.length()) != expectedLength) {
          if (!await targetFile.parent.exists()) {
            await targetFile.parent.create(recursive: true);
          }
          await assetFile.copy(targetFilePath);
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    final String cleanText = TTSNormalizer.removeDiacritics(text.trim());
    if (cleanText.isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }

    if (!_initialized || _tts == null) {
      await initialize();
    }

    while (_synthesisLock != null) {
      await _synthesisLock!.future;
    }
    _synthesisLock = Completer<void>();

    try {
      if (_tts != null && _initialized) {
        final String sampleSnippet = cleanText.length > 30
            ? '${cleanText.substring(0, 30)}...'
            : cleanText;
        debugPrint(
          '[SherpaOnnxTTSEngine FFI PRE-CALL] Chamando _tts!.generate(text: "$sampleSnippet", sid: 0)...',
        );

        final audio = _tts!.generate(text: cleanText, sid: 0, speed: 1.0);

        debugPrint(
          '[SherpaOnnxTTSEngine FFI POST-CALL] Geração C++ concluída com sucesso! (${audio.samples.length} amostras, ${audio.sampleRate}Hz)',
        );

        if (audio.samples.isEmpty) {
          throw const TTSSynthesisException(
            'Sherpa-ONNX generated no audio samples.',
          );
        }

        final Float32List safeSamples = Float32List.fromList(audio.samples);
        final int sampleRate =
            audio.sampleRate > 0 ? audio.sampleRate : config.sampleRate;

        return AudioBuffer(samples: safeSamples, sampleRate: sampleRate);
      }
      throw const TTSSynthesisException('Sherpa-ONNX is not initialized.');
    } catch (e, stack) {
      debugPrint(
        '[SherpaOnnxTTSEngine FFI ERRO] Exceção capturada na inferência C++: $e\n$stack',
      );
      Error.throwWithStackTrace(
        e is TTSSynthesisException
            ? e
            : TTSSynthesisException('Sherpa-ONNX inference failed.', e),
        stack,
      );
    } finally {
      final lock = _synthesisLock;
      _synthesisLock = null;
      lock?.complete();
    }
  }

  @override
  Future<void> dispose() async {
    while (_synthesisLock != null) {
      await _synthesisLock!.future;
    }
    _tts?.free();
    _tts = null;
    _onnxRuntimeLibrary = null;
    _initialized = false;
  }
}
