import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Stub para plataformas nativas (Desktop / Mobile) quando WebSpeechAPI não está disponível.
class WebSpeechEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  bool _initialized = false;

  WebSpeechEngine({TTSConfig? config})
      : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  void queueSentence(String text, {double rate = 1.0}) {}

  void cancelSpeech() {}

  void pauseSpeech() {}

  void resumeSpeech() {}

  @override
  Future<AudioBuffer> synthesize(String text) async {
    final double durationSeconds = math.max(0.8, text.length / 14.0);
    final int numSamples = (durationSeconds * config.sampleRate).round();
    return AudioBuffer(
      samples: Float32List(numSamples),
      sampleRate: config.sampleRate,
    );
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
