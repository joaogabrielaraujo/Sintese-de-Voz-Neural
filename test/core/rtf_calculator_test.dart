import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/metrics/rtf_calculator.dart';

void main() {
  group('RTFCalculator - Testes Unitários de Telemetria de Desempenho', () {
    test('Deve calcular corretamente o fator de tempo real (RTF < 1.0)', () {
      final samples = Float32List(22050 * 5); // 5 segundos de áudio
      final audio = AudioBuffer(samples: samples, sampleRate: 22050);

      // Tempo de inferência: 1000 ms (1 segundo) para gerar 5s de áudio
      final metrics = RTFCalculator.calculate(
        inferenceTimeMs: 1000.0,
        audio: audio,
      );

      expect(metrics.inferenceTimeMs, equals(1000.0));
      expect(metrics.audioDurationSeconds, equals(5.0));
      expect(metrics.rtf, equals(0.2)); // 1.0 / 5.0 = 0.2
      expect(metrics.isRealTime, isTrue);
    });

    test('Deve sinalizar isRealTime = false quando RTF >= 1.0', () {
      final samples = Float32List(22050); // 1 segundo de áudio
      final audio = AudioBuffer(samples: samples, sampleRate: 22050);

      // Tempo de inferência: 2000 ms (2 segundos) para gerar 1s de áudio
      final metrics = RTFCalculator.calculate(
        inferenceTimeMs: 2000.0,
        audio: audio,
      );

      expect(metrics.rtf, equals(2.0));
      expect(metrics.isRealTime, isFalse);
    });
  });
}
