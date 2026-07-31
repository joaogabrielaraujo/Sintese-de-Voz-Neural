import 'package:flutter/foundation.dart';
import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'sherpa_onnx_cli_engine.dart';
import 'sherpa_onnx_engine.dart';
import 'tts_engine_interface.dart';
import 'tts_engine_type.dart';

/// Motor Composto Resiliente com Failover Automático Transparente.
///
/// Tenta inicializar o motor neural primário Sherpa-ONNX (C++ VITS HiFi-GAN).
/// Se a DLL nativa não estiver presente, chaveia automaticamente e sem travamentos
/// para os motores de reserva (FlutterTTS Nativo do Sistema ou VITS Local).
class CompositeTTSEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  TTSEngineType _selectedType;
  ITTSEngine? _activeEngine;
  TTSEngineType? _activeType;

  final ITTSEngine _sherpaEngine;
  final ITTSEngine _cliEngine;

  CompositeTTSEngine({
    TTSConfig? config,
    TTSEngineType initialType = TTSEngineType.autoFailover,
    ITTSEngine? sherpaEngine,
    ITTSEngine? cliEngine,
  }) : config = config ?? TTSConfig.defaultPtBr(),
       _selectedType = initialType,
       _sherpaEngine =
           sherpaEngine ??
           SherpaOnnxTTSEngine(config: config ?? TTSConfig.defaultPtBr()),
       _cliEngine =
           cliEngine ??
           SherpaOnnxCliEngine(config: config ?? TTSConfig.defaultPtBr());

  TTSEngineType get selectedType => _selectedType;
  TTSEngineType? get activeType => _activeType;

  Future<void> setEngineType(TTSEngineType newType) async {
    if (_selectedType == newType) return;
    await _activeEngine?.dispose();
    _selectedType = newType;
    _activeEngine = null;
    _activeType = null;
    await initialize();
  }

  @override
  bool get isInitialized => _activeEngine?.isInitialized ?? false;

  @override
  Future<void> initialize() async {
    switch (_selectedType) {
      case TTSEngineType.sherpaOnnx:
        await _initializeRequired(_sherpaEngine, TTSEngineType.sherpaOnnx);
        break;

      case TTSEngineType.sherpaOnnxCli:
        await _initializeRequired(_cliEngine, TTSEngineType.sherpaOnnxCli);
        break;

      case TTSEngineType.vitsLocal:
      case TTSEngineType.flutterTts:
        throw TTSEngineInitializationException(
          '${_selectedType.label} does not implement the AudioBuffer contract and is unavailable.',
        );

      case TTSEngineType.autoFailover:
        final sherpaOk = await _tryInitializeEngine(_sherpaEngine);
        if (sherpaOk && _sherpaEngine.isInitialized) {
          _activeEngine = _sherpaEngine;
          _activeType = TTSEngineType.sherpaOnnx;
          debugPrint(
            '[CompositeTTSEngine] Motor Primário Ativado: Sherpa-ONNX C++ VITS Neural',
          );
          break;
        }

        final cliOk = await _tryInitializeEngine(_cliEngine);
        if (cliOk && _cliEngine.isInitialized) {
          _activeEngine = _cliEngine;
          _activeType = TTSEngineType.sherpaOnnxCli;
          debugPrint(
            '[CompositeTTSEngine] Motor de fallback ativado: Sherpa-ONNX CLI',
          );
          break;
        }

        throw const TTSEngineInitializationException(
          'No real AudioBuffer-producing TTS engine is available. Configure Sherpa FFI or CLI with a complete model and espeak-ng-data.',
        );
    }
  }

  Future<void> _initializeRequired(
    ITTSEngine engine,
    TTSEngineType type,
  ) async {
    await engine.initialize();
    if (!engine.isInitialized) {
      throw TTSEngineInitializationException(
        '${type.label} did not finish initialization.',
      );
    }
    _activeEngine = engine;
    _activeType = type;
  }

  Future<bool> _tryInitializeEngine(ITTSEngine engine) async {
    try {
      await engine.initialize();
      return engine.isInitialized;
    } catch (e) {
      debugPrint(
        '[CompositeTTSEngine] Falha ao inicializar motor (${engine.runtimeType}): $e',
      );
      return false;
    }
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (text.trim().isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }
    if (!isInitialized || _activeEngine == null) {
      await initialize();
    }

    try {
      final AudioBuffer result = await _activeEngine!.synthesize(text);
      _validateAudio(result);
      return result;
    } catch (e, stack) {
      debugPrint(
        '[CompositeTTSEngine] Falha na síntese com motor (${_activeEngine.runtimeType}): $e',
      );
      if (_selectedType == TTSEngineType.autoFailover &&
          _activeEngine != _cliEngine &&
          await _tryInitializeEngine(_cliEngine)) {
        _activeEngine = _cliEngine;
        _activeType = TTSEngineType.sherpaOnnxCli;
        final fallbackResult = await _cliEngine.synthesize(text);
        _validateAudio(fallbackResult);
        return fallbackResult;
      }
      Error.throwWithStackTrace(
        e is TTSSynthesisException
            ? e
            : TTSSynthesisException('All configured TTS engines failed.', e),
        stack,
      );
    }
  }

  void _validateAudio(AudioBuffer audio) {
    if (audio.sampleRate <= 0 || audio.numChannels <= 0) {
      throw const TTSSynthesisException(
        'TTS returned an invalid audio format.',
      );
    }
    if (audio.samples.isEmpty ||
        audio.samples.length % audio.numChannels != 0) {
      throw const TTSSynthesisException(
        'TTS returned no complete audio frames.',
      );
    }

    double peak = 0.0;
    for (final sample in audio.samples) {
      if (!sample.isFinite) {
        throw const TTSSynthesisException('TTS returned non-finite samples.');
      }
      final magnitude = sample.abs();
      if (magnitude > peak) peak = magnitude;
    }
    if (peak <= 0.00001) {
      throw const TTSSynthesisException(
        'TTS returned effectively silent audio.',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _sherpaEngine.dispose();
    await _cliEngine.dispose();
    _activeEngine = null;
    _activeType = null;
  }
}
