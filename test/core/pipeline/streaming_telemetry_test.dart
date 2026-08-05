import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/memory/sentence_audio_item.dart';
import 'package:tcc_tts_neural/core/metrics/rtf_calculator.dart';
import 'package:tcc_tts_neural/core/pipeline/streaming_telemetry.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';

void main() {
  group('StreamingTelemetryAccumulator', () {
    test('accepted item exposes real RTF and calculates formula correctly', () {
      final accumulator = StreamingTelemetryAccumulator();

      final item = SentenceAudioItem(
        rawSentence: const TextSentence(index: 0, text: 'Primeira frase de teste.'),
        normalizedText: 'Primeira frase de teste.',
        audio: AudioBuffer(
          samples: Float32List(16000), // 1 sec of 16kHz audio
          sampleRate: 16000,
        ),
        metrics: const PerformanceMetrics(
          inferenceTimeMs: 250.0,
          audioDurationSeconds: 1.0,
          rtf: 0.25,
        ),
      );

      accumulator.addAcceptedItem(item);
      final snapshot = accumulator.snapshot(memoryMb: 12.5);

      expect(snapshot.isEmpty, isFalse);
      expect(snapshot.items.length, 1);
      expect(snapshot.items.first.index, 0);
      expect(snapshot.items.first.text, 'Primeira frase de teste.');
      expect(snapshot.items.first.audioDuration.inSeconds, 1);
      expect(snapshot.items.first.synthesisDuration.inMilliseconds, 250);
      expect(snapshot.overallRtf, closeTo(0.25, 0.01));

      final report = snapshot.generateAcademicReport();
      expect(report.contains('Real-Time Factor (RTF) Médio: 0.250'), isTrue);
      expect(report.contains('Sentenças Processadas: 1'), isTrue);
    });

    test('empty accumulator returns null overallRtf and prints empty status', () {
      final accumulator = StreamingTelemetryAccumulator();
      final snapshot = accumulator.snapshot();

      expect(snapshot.isEmpty, isTrue);
      expect(snapshot.overallRtf, isNull);
    });
  });
}
