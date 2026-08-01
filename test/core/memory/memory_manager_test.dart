import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/memory/memory_manager.dart';
import 'package:tcc_tts_neural/core/metrics/rtf_calculator.dart';
import 'package:tcc_tts_neural/core/memory/sentence_audio_item.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';

SentenceAudioItem _createMockItem(int index, int numSamples) {
  return SentenceAudioItem(
    rawSentence: TextSentence(
      index: index,
      text: 'Sentença $index',
    ),
    normalizedText: 'Sentença $index',
    audio: AudioBuffer(
      samples: Float32List(numSamples),
      sampleRate: 22050,
    ),
    metrics: const PerformanceMetrics(
      inferenceTimeMs: 10.0,
      audioDurationSeconds: 1.0,
      rtf: 0.01,
    ),
  );
}

void main() {
  group('MemoryManager Unit Tests (Fase 8)', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager();
    });

    test('Rastreamento de alocação de memória RAM em bytes e MB', () {
      // 22050 amostras Float32 = 88.200 bytes (~0.084 MB)
      final item = _createMockItem(0, 22050);
      memoryManager.trackAllocation(item);

      expect(memoryManager.stats.allocatedBytes, equals(88200));
      expect(memoryManager.stats.allocatedMb, closeTo(0.084, 0.01));
    });

    test('Purge automático desaloca memória e atualiza estatísticas', () {
      final item = _createMockItem(0, 22050);
      memoryManager.trackAllocation(item);
      expect(memoryManager.stats.allocatedBytes, equals(88200));

      memoryManager.purge(item);

      expect(memoryManager.stats.allocatedBytes, equals(0));
      expect(memoryManager.stats.freedBytes, equals(88200));
      expect(memoryManager.stats.purgedItemsCount, equals(1));
    });

    test('Throttling do Produtor quando teto de RAM é atingido', () {
      // Cria item com 15.000.000 amostras Float32 (~60MB de RAM)
      final itemGrande = _createMockItem(0, 15000000);
      memoryManager.trackAllocation(itemGrande);

      expect(memoryManager.shouldThrottleProducer(maxMemoryMb: 50.0), isTrue);

      memoryManager.purge(itemGrande);
      expect(memoryManager.shouldThrottleProducer(maxMemoryMb: 50.0), isFalse);
    });
  });
}
