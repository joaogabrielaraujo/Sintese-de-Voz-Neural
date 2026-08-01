import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import '../text/tts_normalizer.dart';
import 'tts_engine_interface.dart';

typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      required bool runInShell,
    });

/// Motor de Inferência Neural VITS via Processo Isolado CLI (`sherpa-onnx-offline-tts`).
///
/// Executa a síntese de voz em um processo separado do sistema operacional (`Process.run`),
/// isolando a inferência C++/ONNX e garantindo imunidade total contra Segmentation Faults
/// e fechamentos abruptos na VM Dart do Flutter.
class SherpaOnnxCliEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  /// Caminho personalizado opcional para o executável do Sherpa CLI
  final String? customCliPath;
  final ProcessRunner? processRunner;
  final Directory? modelDirectory;

  bool _initialized = false;
  String? _cliExecutablePath;
  String? _absModelPath;
  String? _absTokensPath;
  String? _absEspeakDataDir;

  SherpaOnnxCliEngine({
    TTSConfig? config,
    this.customCliPath,
    this.processRunner,
    this.modelDirectory,
  }) : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized && _cliExecutablePath != null;

  String? get cliExecutablePath => _cliExecutablePath;

  @override
  Future<void> initialize() async {
    if (_initialized && _cliExecutablePath != null) return;

    try {
      // 1. Resolver diretório local de modelos
      Directory modelDir;
      if (modelDirectory != null) {
        modelDir = modelDirectory!;
      } else {
        Directory docDir;
        try {
          docDir = await getApplicationDocumentsDirectory();
        } catch (_) {
          docDir = Directory.current;
        }
        modelDir = Directory(p.join(docDir.path, 'models'));
      }
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // 2. Extrair assets do modelo e tokens
      final String rawModelPath = p.join(
        modelDir.path,
        'pt_BR-faber-medium.onnx',
      );
      final String rawTokensPath = p.join(modelDir.path, 'tokens.txt');

      await _copyAssetToFileWithValidation(config.modelPath, rawModelPath);
      await _copyAssetToFileWithValidation(config.tokensPath, rawTokensPath);

      _absModelPath = await _validateAndGetAbsolutePath(rawModelPath);
      _absTokensPath = await _validateAndGetAbsolutePath(rawTokensPath);
      _absEspeakDataDir = await _validateEspeakDataDirectory();

      // 3. Localizar o executável do Sherpa CLI (sherpa-onnx-offline-tts)
      _cliExecutablePath = await _findCliExecutable();

      if (_cliExecutablePath != null) {
        _initialized = true;
        debugPrint(
          '[SherpaOnnxCliEngine] Motor CLI inicializado com sucesso. Binário: $_cliExecutablePath',
        );
      } else {
        _initialized = false;
        debugPrint(
          '[SherpaOnnxCliEngine WARNING] Executável "sherpa-onnx-offline-tts" não encontrado no sistema/PATH.',
        );
        throw const TTSEngineInitializationException(
          'sherpa-onnx-offline-tts executable was not found.',
        );
      }
    } catch (e, stack) {
      debugPrint(
        '[SherpaOnnxCliEngine] Erro na inicialização do CLI Engine: $e\n$stack',
      );
      _initialized = false;
      _cliExecutablePath = null;
      Error.throwWithStackTrace(
        TTSEngineInitializationException(
          'Could not initialize the Sherpa-ONNX CLI engine.',
          e,
        ),
        stack,
      );
    }
  }

  /// Tenta localizar o executável sherpa-onnx-offline-tts no sistema, pasta do projeto ou PATH
  Future<String?> _findCliExecutable() async {
    final String exeName = Platform.isWindows
        ? 'sherpa-onnx-offline-tts.exe'
        : 'sherpa-onnx-offline-tts';

    // 1. Caminho explícito fornecido
    if (customCliPath != null && await File(customCliPath!).exists()) {
      return File(customCliPath!).absolute.path;
    }

    // 2. Pasta atual / bin /
    final List<String> candidatePaths = [
      p.join(Directory.current.path, exeName),
      p.join(Directory.current.path, 'bin', exeName),
      p.join(Directory.current.path, 'windows', 'bin', exeName),
      p.join(Directory.current.path, 'assets', 'bin', exeName),
    ];

    for (final path in candidatePaths) {
      if (await File(path).exists()) {
        return File(path).absolute.path;
      }
    }

    // 3. Pesquisar no PATH do sistema via comando 'where' (Windows) ou 'which' (Linux/macOS)
    try {
      final String searchCmd = Platform.isWindows ? 'where' : 'which';
      final result = await _runProcess(searchCmd, [exeName]);
      if (result.exitCode == 0) {
        final String foundPath = result.stdout
            .toString()
            .split(RegExp(r'[\r\n]+'))
            .first
            .trim();
        if (foundPath.isNotEmpty && await File(foundPath).exists()) {
          return File(foundPath).absolute.path;
        }
      }
    } catch (_) {}

    // Se não encontrou o executável no disco nem no PATH, retorna null
    return null;
  }

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

  Future<String> _validateEspeakDataDirectory() async {
    final configuredPath = config.espeakDataPath?.trim();
    if (configuredPath == null || configuredPath.isEmpty) {
      throw const TTSEngineInitializationException(
        'This Piper voice requires a complete espeak-ng-data directory. Configure TTSConfig.espeakDataPath.',
      );
    }

    final directory = Directory(configuredPath).absolute;
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
    return directory.path;
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
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await targetFile.writeAsBytes(bytes, flush: true);
      }
    } catch (_) {
      final File assetFile = File(assetPath);
      if (await assetFile.exists()) {
        final int expectedLength = await assetFile.length();
        if (!await targetFile.exists() ||
            (await targetFile.length()) != expectedLength) {
          await assetFile.copy(targetFilePath);
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }

    if (!_initialized || _cliExecutablePath == null) {
      await initialize();
    }
    if (!_initialized ||
        _cliExecutablePath == null ||
        _absModelPath == null ||
        _absTokensPath == null ||
        _absEspeakDataDir == null) {
      throw const TTSSynthesisException('Sherpa-ONNX CLI is not initialized.');
    }

    // Gerar caminho temporário único no disco para a saída do áudio WAV
    final String tempWavPath = p.join(
      Directory.systemTemp.path,
      'tts_cli_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    final File tempWavFile = File(tempWavPath);

    try {
      debugPrint(
        '[SherpaOnnxCliEngine] Executando processo CLI isolado: $_cliExecutablePath',
      );

      final arguments = <String>[
        '--vits-model=$_absModelPath',
        '--vits-tokens=$_absTokensPath',
        '--vits-data-dir=$_absEspeakDataDir',
        '--output-filename=$tempWavPath',
        cleanText,
      ];
      final ProcessResult result = await _runProcess(
        _cliExecutablePath!,
        arguments,
      );

      if (result.exitCode != 0) {
        final String errorMsg = result.stderr.toString().trim();
        debugPrint(
          '[SherpaOnnxCliEngine ERROR] Processo CLI falhou (Exit Code ${result.exitCode}): $errorMsg',
        );
        throw ProcessException(
          _cliExecutablePath!,
          arguments,
          errorMsg.isNotEmpty
              ? errorMsg
              : 'Falha na execução do executável sherpa-onnx-offline-tts',
          result.exitCode,
        );
      }

      if (await tempWavFile.exists()) {
        final Uint8List wavBytes = await tempWavFile.readAsBytes();
        final AudioBuffer decodedBuffer = WavWriter.decodeWav(wavBytes);

        debugPrint(
          '[SherpaOnnxCliEngine SUCESSO] Áudio sintetizado via CLI: ${decodedBuffer.samples.length} amostras, ${decodedBuffer.durationInSeconds.toStringAsFixed(2)}s',
        );
        return decodedBuffer;
      } else {
        throw FileSystemException(
          'Arquivo WAV temporário não foi gerado pelo processo CLI',
          tempWavPath,
        );
      }
    } catch (e) {
      debugPrint(
        '[SherpaOnnxCliEngine EXCEÇÃO] Erro durante síntese por processo CLI isolado: $e',
      );
      rethrow;
    } finally {
      // Garantir limpeza do arquivo temporário WAV no disco
      if (await tempWavFile.exists()) {
        await tempWavFile.delete().catchError((_) => tempWavFile);
      }
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }

  Future<ProcessResult> _runProcess(String executable, List<String> arguments) {
    final runner = processRunner;
    if (runner != null) {
      return runner(executable, arguments, runInShell: false);
    }
    return Process.run(executable, arguments, runInShell: false);
  }
}
