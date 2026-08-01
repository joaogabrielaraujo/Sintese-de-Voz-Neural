import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Motor Mock de Inferência Neural para Suíte de Testes, Demonstração e Benchmark.
///
/// Simula a cadência prosódica e modulada da voz humana (F0 variável ~130Hz com formantes e silêncios entre sílabas)
/// para evitar apitos/tons estáticos piercing de 440Hz.
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

    // Simula a latência de inferência
    final int delayMs = (text.length * msPerCharacter).round();
    await Future.delayed(Duration(milliseconds: delayMs));

    // Estima a duração do áudio em segundos com base na extensão do texto
    final double durationSeconds = math.max(0.6, text.length / 14.0);
    final int numSamples = (durationSeconds * config.sampleRate).round();
    final Float32List samples = Float32List(numSamples);

    double phase = 0.0;
    const double baseF0 = 135.0; // Frequência fundamental média de voz humana em Hz

    for (int i = 0; i < numSamples; i++) {
      final double t = i / config.sampleRate;

      // 1. Modulação de Pitch (Prosódia/Entonação): variação suave da voz entre ~120Hz e 155Hz
      final double currentF0 = baseF0 + 20.0 * math.sin(2 * math.pi * 1.8 * t);

      // 2. Acúmulo de Fase para síntese contínua sem cliques de áudio
      phase += 2 * math.pi * currentF0 / config.sampleRate;

      // 3. Envelope de Ritmo Silábico: simula 4.5 sílabas/palavras por segundo com pequenas pausas
      final double syllableRhythm = math.max(0.0, math.sin(2 * math.pi * 4.5 * t));
      final double envelope = math.pow(syllableRhythm, 1.4).toDouble();

      // 4. Síntese Harmônica (Formantes de tom de voz suave): Fundamental + 2º e 3º Harmônicos
      final double fundamental = math.sin(phase);
      final double secondHarmonic = 0.3 * math.sin(phase * 2.0);
      final double thirdHarmonic = 0.1 * math.sin(phase * 3.0);
      final double voiceWave = (fundamental + secondHarmonic + thirdHarmonic) / 1.4;

      // 5. Aplica o envelope prosódico com volume confortável (0.25 max)
      samples[i] = (0.25 * envelope * voiceWave).clamp(-1.0, 1.0);
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
