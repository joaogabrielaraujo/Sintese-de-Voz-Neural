import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/metrics/rtf_calculator.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_result.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';

void main() {
  test('combines stereo frames and retains punctuation-aware timeline', () {
    const metrics = PerformanceMetrics(
      inferenceTimeMs: 1,
      audioDurationSeconds: 0.1,
      rtf: 0.01,
    );
    final audio = AudioBuffer(
      samples: Float32List(200),
      sampleRate: 1000,
      numChannels: 2,
    );
    final result = PipelineResult(
      bookTitle: 'Book',
      chapterTitle: 'Chapter',
      items: [
        ProcessedSentenceItem(
          rawSentence: const TextSentence(
            index: 0,
            text: 'Question?',
            isParagraphEnd: false,
          ),
          normalizedText: 'Question?',
          audio: audio,
          metrics: metrics,
        ),
        ProcessedSentenceItem(
          rawSentence: const TextSentence(
            index: 1,
            text: 'Answer.',
            isParagraphEnd: true,
          ),
          normalizedText: 'Answer.',
          audio: audio,
          metrics: metrics,
        ),
      ],
      totalInferenceTimeMs: 2,
      totalAudioDurationSeconds: 0.2,
      overallRtf: 0.01,
    );

    final decoded = WavWriter.decodeWav(result.combinedWavBytes);
    expect(decoded.samples, hasLength(200 + (230 * 2) + 200));
    expect(result.timeline[0].start, Duration.zero);
    expect(result.timeline[0].speechEnd, const Duration(milliseconds: 100));
    expect(result.timeline[0].end, const Duration(milliseconds: 330));
    expect(result.timeline[1].start, const Duration(milliseconds: 330));
  });

  test('rejects mismatched sentence audio formats', () {
    const metrics = PerformanceMetrics(
      inferenceTimeMs: 1,
      audioDurationSeconds: 0.1,
      rtf: 0.01,
    );
    final result = PipelineResult(
      bookTitle: 'Book',
      chapterTitle: 'Chapter',
      items: [
        ProcessedSentenceItem(
          rawSentence: const TextSentence(
            index: 0,
            text: 'A.',
            isParagraphEnd: false,
          ),
          normalizedText: 'A.',
          audio: AudioBuffer(samples: Float32List(10), sampleRate: 1000),
          metrics: metrics,
        ),
        ProcessedSentenceItem(
          rawSentence: const TextSentence(
            index: 1,
            text: 'B.',
            isParagraphEnd: true,
          ),
          normalizedText: 'B.',
          audio: AudioBuffer(samples: Float32List(10), sampleRate: 2000),
          metrics: metrics,
        ),
      ],
      totalInferenceTimeMs: 2,
      totalAudioDurationSeconds: 0.2,
      overallRtf: 0.01,
    );

    expect(() => result.combinedWavBytes, throwsStateError);
  });
}
