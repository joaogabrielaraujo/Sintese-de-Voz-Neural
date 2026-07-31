import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/metrics/rtf_calculator.dart';
import 'package:tcc_tts_neural/core/memory/circular_audio_buffer.dart';
import 'package:tcc_tts_neural/core/memory/sentence_audio_item.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';

SentenceAudioItem _createMockItem(int index, String text) {
  return SentenceAudioItem(
    rawSentence: TextSentence(
      index: index,
      text: text,
    ),
    normalizedText: text,
    audio: AudioBuffer(
      samples: Float32List.fromList([0.1, 0.2, 0.3]),
      sampleRate: 22050,
    ),
    metrics: const PerformanceMetrics(
      inferenceTimeMs: 15.0,
      audioDurationSeconds: 1.0,
      rtf: 0.015,
    ),
  );
}

void main() {
  group('CircularAudioBuffer Concurrency Tests', () {
    late CircularAudioBuffer buffer;

    setUp(() {
      buffer = CircularAudioBuffer(maxItems: 3);
    });

    tearDown(() {
      buffer.dispose();
    });

    test('Ordem FIFO (First-In, First-Out) dos itens', () async {
      final item1 = _createMockItem(0, 'Primeira sentença');
      final item2 = _createMockItem(1, 'Segunda sentença');

      await buffer.enqueue(item1);
      await buffer.enqueue(item2);

      expect(buffer.length, equals(2));

      final popped1 = await buffer.dequeue();
      expect(popped1?.rawSentence.text, equals('Primeira sentença'));

      final popped2 = await buffer.dequeue();
      expect(popped2?.rawSentence.text, equals('Segunda sentença'));

      expect(buffer.isEmpty, isTrue);
    });

    test('Controle de capacidade maxima e Backpressure', () async {
      final item1 = _createMockItem(0, 'Item 1');
      final item2 = _createMockItem(1, 'Item 2');
      final item3 = _createMockItem(2, 'Item 3');
      final item4 = _createMockItem(3, 'Item 4');

      await buffer.enqueue(item1);
      await buffer.enqueue(item2);
      await buffer.enqueue(item3);

      expect(buffer.isFull, isTrue);

      bool item4Enqueued = false;

      // Executa o enqueue em background pois deve pausar devido ao backpressure
      Future.microtask(() async {
        await buffer.enqueue(item4);
        item4Enqueued = true;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(item4Enqueued, isFalse); // Pausado por capacidade cheia

      // Consome 1 item para liberar espaço
      final popped = await buffer.dequeue();
      expect(popped?.rawSentence.text, equals('Item 1'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(item4Enqueued, isTrue); // Liberado após o dequeue
    });

    test('Consumo assíncrono paralelo entre Produtor e Consumidor', () async {
      final producedItems = <String>[];
      final consumedItems = <String>[];

      // Produtor
      Future<void> producer() async {
        for (int i = 0; i < 5; i++) {
          final item = _createMockItem(i, 'Sentença $i');
          await buffer.enqueue(item);
          producedItems.add('Sentença $i');
          await Future.delayed(const Duration(milliseconds: 10));
        }
        buffer.markComplete();
      }

      // Consumidor
      Future<void> consumer() async {
        while (!buffer.isCompleted || !buffer.isEmpty) {
          final item = await buffer.dequeue();
          if (item != null) {
            consumedItems.add(item.rawSentence.text);
          }
        }
      }

      await Future.wait([producer(), consumer()]);

      expect(consumedItems.length, equals(5));
      expect(consumedItems, equals(producedItems));
    });

    test('Streaming mantém áudio até liberação explícita', () async {
      final item = _createMockItem(0, 'Áudio atual');

      await buffer.enqueue(item);
      final consumed = await buffer.dequeue(release: false);

      expect(consumed, same(item));
      expect(buffer.memoryManager.stats.allocatedBytes, greaterThan(0));

      buffer.release(item);

      expect(buffer.memoryManager.stats.allocatedBytes, equals(0));
      expect(item.audio.samples.every((sample) => sample == 0.0), isTrue);
    });

    test('Cancelamento libera fila e desbloqueia produtor', () async {
      final first = _createMockItem(0, 'Primeiro');
      final second = _createMockItem(1, 'Segundo');
      final third = _createMockItem(2, 'Terceiro');
      final fourth = _createMockItem(3, 'Quarto');

      await buffer.enqueue(first);
      await buffer.enqueue(second);
      await buffer.enqueue(third);
      final blockedEnqueue = buffer.enqueue(fourth);

      buffer.cancel();

      await expectLater(blockedEnqueue, throwsStateError);
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isCompleted, isTrue);
      expect(buffer.memoryManager.stats.allocatedBytes, equals(0));
    });
  });
}
