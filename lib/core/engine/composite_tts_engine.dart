import 'package:flutter/foundation.dart';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'sherpa_onnx_cli_engine.dart';
import 'sherpa_onnx_engine.dart';
import 'tts_engine_interface.dart';
import 'tts_engine_type.dart';

/// Motor composto com seleção explícita e failover entre motores locais.
class CompositeTTSEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  TTSEngineType _selectedType;
  ITTSEngine? _activeEngine;
  TTSEngineType? _activeType;

  final ITTSEngine _sherpaEngine;
  final ITTSEngine _cliEngine;
  final ITTSEngine? _supertonicEngine;

  CompositeTTSEngine({
    TTSConfig? config,
    TTSEngineType initialType = TTSEngineType.autoFailover,
    ITTSEngine? sherpaEngine,
    ITTSEngine? cliEngine,
    ITTSEngine? supertonicEngine,
  })  : config = config ?? TTSConfig.defaultPtBr(),
        _selectedType = initialType,
        _supertonicEngine = supertonicEngine,
        _sherpaEngine = sherpaEngine ??
            SherpaOnnxTTSEngine(config: config ?? TTSConfig.defaultPtBr()),
        _cliEngine = cliEngine ??
            SherpaOnnxCliEngine(config: config ?? TTSConfig.defaultPtBr());

  TTSEngineType get selectedType => _selectedType;
  TTSEngineType? get activeType => _activeType;
  bool get hasSupertonic => _supertonicEngine != null;

  List<TTSEngineType> get availableEngineTypes => [
        TTSEngineType.autoFailover,
        if (hasSupertonic) TTSEngineType.supertonic,
        TTSEngineType.sherpaOnnx,
        TTSEngineType.sherpaOnnxCli,
      ];

  List<(ITTSEngine, TTSEngineType)> get _autoCandidates => [
        if (_supertonicEngine != null)
          (_supertonicEngine!, TTSEngineType.supertonic),
        (_sherpaEngine, TTSEngineType.sherpaOnnx),
        (_cliEngine, TTSEngineType.sherpaOnnxCli),
      ];

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
      case TTSEngineType.supertonic:
        final engine = _supertonicEngine;
        if (engine == null) {
          throw const TTSEngineInitializationException(
            'Supertonic 3 não está instalado neste dispositivo.',
          );
        }
        await _initializeRequired(engine, TTSEngineType.supertonic);
      case TTSEngineType.sherpaOnnx:
        await _initializeRequired(_sherpaEngine, TTSEngineType.sherpaOnnx);
      case TTSEngineType.sherpaOnnxCli:
        await _initializeRequired(_cliEngine, TTSEngineType.sherpaOnnxCli);
      case TTSEngineType.vitsLocal:
      case TTSEngineType.flutterTts:
        throw TTSEngineInitializationException(
          '${_selectedType.label} não implementa o contrato AudioBuffer.',
        );
      case TTSEngineType.autoFailover:
        for (final candidate in _autoCandidates) {
          if (await _activateCandidate(candidate)) break;
        }
        if (_activeEngine == null) {
          throw const TTSEngineInitializationException(
            'Nenhum motor TTS local está disponível. Instale o Supertonic ou configure Sherpa FFI/CLI.',
          );
        }
    }
  }

  Future<void> _initializeRequired(
    ITTSEngine engine,
    TTSEngineType type,
  ) async {
    await engine.initialize();
    if (!engine.isInitialized) {
      throw TTSEngineInitializationException(
        '${type.label} não concluiu a inicialização.',
      );
    }
    _activeEngine = engine;
    _activeType = type;
  }

  Future<bool> _tryInitializeEngine(ITTSEngine engine) async {
    try {
      await engine.initialize();
      return engine.isInitialized;
    } on Object catch (error) {
      debugPrint(
        '[CompositeTTSEngine] Falha ao inicializar ${engine.runtimeType}: $error',
      );
      return false;
    }
  }

  Future<bool> _activateCandidate((ITTSEngine, TTSEngineType) candidate) async {
    if (!await _tryInitializeEngine(candidate.$1)) return false;
    _activeEngine = candidate.$1;
    _activeType = candidate.$2;
    debugPrint('[CompositeTTSEngine] Motor ativado: ${candidate.$2.label}');
    return true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (text.trim().isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }
    if (!isInitialized || _activeEngine == null) await initialize();

    try {
      final result = await _activeEngine!.synthesize(text);
      _validateAudio(result);
      return result;
    } on Object catch (error, stack) {
      debugPrint(
        '[CompositeTTSEngine] Falha na síntese com ${_activeEngine.runtimeType}: $error',
      );
      if (_selectedType == TTSEngineType.autoFailover) {
        final currentIndex = _autoCandidates.indexWhere(
          (candidate) => identical(candidate.$1, _activeEngine),
        );
        for (final candidate in _autoCandidates.skip(currentIndex + 1)) {
          if (!await _activateCandidate(candidate)) continue;
          try {
            final fallback = await candidate.$1.synthesize(text);
            _validateAudio(fallback);
            return fallback;
          } on Object catch (fallbackError) {
            debugPrint(
              '[CompositeTTSEngine] Falha no fallback ${candidate.$2.label}: $fallbackError',
            );
          }
        }
      }
      Error.throwWithStackTrace(
        error is TTSSynthesisException
            ? error
            : TTSSynthesisException('Todos os motores TTS falharam.', error),
        stack,
      );
    }
  }

  void _validateAudio(AudioBuffer audio) {
    if (audio.sampleRate <= 0 || audio.numChannels <= 0) {
      throw const TTSSynthesisException('Formato de áudio TTS inválido.');
    }
    if (audio.samples.isEmpty ||
        audio.samples.length % audio.numChannels != 0) {
      throw const TTSSynthesisException('TTS não retornou quadros completos.');
    }
    var peak = 0.0;
    for (final sample in audio.samples) {
      if (!sample.isFinite) {
        throw const TTSSynthesisException('TTS retornou amostras não finitas.');
      }
      if (sample.abs() > peak) peak = sample.abs();
    }
    if (peak <= 0.00001) {
      throw const TTSSynthesisException('TTS retornou áudio silencioso.');
    }
  }

  @override
  Future<void> dispose() async {
    await _supertonicEngine?.dispose();
    await _sherpaEngine.dispose();
    await _cliEngine.dispose();
    _activeEngine = null;
    _activeType = null;
  }
}
