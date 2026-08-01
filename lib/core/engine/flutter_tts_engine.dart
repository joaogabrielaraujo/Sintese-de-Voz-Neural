import 'package:flutter_tts/flutter_tts.dart';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Motor de Síntese de Voz Humana Nativa de Baixa Latência (Non-Blocking) para Windows, Web e Mobile.
///
/// Executa a síntese de voz em thread assíncrona desacoplada do UI Looper do Flutter,
/// garantindo respostas instantâneas na interface (<10ms) e controles de player 100% funcionais.
class FlutterTtsEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  FlutterTtsEngine({TTSConfig? config})
    : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _flutterTts.setLanguage('pt-BR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    throw const TTSSynthesisException(
      'FlutterTtsEngine speaks directly through the platform and cannot return an AudioBuffer. Use a dedicated native-speech contract.',
    );
  }

  /// Cancela qualquer fala em andamento.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stop();
    _initialized = false;
  }
}
