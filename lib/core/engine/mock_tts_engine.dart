import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import '../metrics/rtf_calculator.dart';
import 'tts_engine_interface.dart';

/// Motor Mock de Inferência Neural para Suíte de Testes e Benchmark de Pipeline.
///
/// Simula o comportamento do VITS ONNX com latência controlada e geração determinística de áudio.
class MockTTSEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  /// Fator de velocidade de inferência simulada (ms por caractere).
  final double msPerCharacter;

  bool _initialized = false;

  MockTTSEngine({
    TTSConfig? config,
    this.msPerCharacter = 1.5,
  }) : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 10));
    _initialized = true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }

    final int delayMs = (text.length * msPerCharacter).round();
    await Future.delayed(Duration(milliseconds: delayMs));

    final double durationSeconds = math.max(0.5, text.length / 14.0);
    final int numSamples = (durationSeconds * config.sampleRate).round();

    final Float32List samples = Float32List(numSamples);
    const double frequency = 440.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / config.sampleRate;
      samples[i] = (0.4 * math.sin(2 * math.pi * frequency * t)).toDouble();
    }

    return AudioBuffer(
      samples: samples,
      sampleRate: config.sampleRate,
    );
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
