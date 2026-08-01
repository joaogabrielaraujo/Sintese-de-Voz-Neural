import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/mock_tts_engine.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_orchestrator.dart';
import 'package:tcc_tts_neural/core/memory/circular_audio_buffer.dart';
import 'package:tcc_tts_neural/core/memory/sentence_audio_item.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';

class FailingMockTTSEngine extends MockTTSEngine {
  int calls = 0;

  @override
  Future<AudioBuffer> synthesize(String text) async {
    calls += 1;
    if (calls == 3) throw StateError('controlled synthesis failure');
    return super.synthesize(text);
  }
}

void main() {
  group('PipelineOrchestrator Streaming Tests (Fase 7)', () {
    late MockTTSEngine engine;
    late PipelineOrchestrator orchestrator;

    setUp(() {
      engine = MockTTSEngine(config: TTSConfig.defaultPtBr());
      orchestrator = PipelineOrchestrator(engine: engine);
    });

    tearDown(() {
      engine.dispose();
    });

    test(
      'Deve processar capítulo em streaming e alimentar a CircularAudioBuffer',
      () async {
        final book = const EpubBook(
          title: 'Livro de Teste',
          author: 'Autor Teste',
          chapters: [
            EpubChapter(
              index: 0,
              id: 'c1',
              title: 'Capítulo 1',
              rawHtml: '<p>Primeira frase. Segunda frase. Terceira frase.</p>',
              cleanText: 'Primeira frase. Segunda frase. Terceira frase.',
            ),
          ],
        );

        final queue = CircularAudioBuffer(maxItems: 5);
        final receivedItems = <SentenceAudioItem>[];

        final Stopwatch stopwatch = Stopwatch()..start();
        double? ttfaMs; // Time To First Audio

        final stream = orchestrator.processChapterStream(
          book: book,
          chapter: book.chapters.first,
          queue: queue,
        );

        await for (final item in stream) {
          if (ttfaMs == null) {
            ttfaMs = stopwatch.elapsedMilliseconds.toDouble();
          }
          receivedItems.add(item);
        }

        stopwatch.stop();

        expect(receivedItems.length, equals(3));
        expect(queue.isCompleted, isTrue);
        expect(ttfaMs, isNotNull);
        // TTFA deve ser significativamente menor que o tempo total da síntese do capítulo
        expect(ttfaMs!, lessThan(stopwatch.elapsedMilliseconds.toDouble()));

        queue.dispose();
      },
    );

    test('consome mais sentenças que a capacidade sem deadlock', () async {
      final book = const EpubBook(
        title: 'Livro',
        author: 'Autor',
        chapters: [
          EpubChapter(
            index: 0,
            id: 'c1',
            title: 'Capítulo',
            rawHtml: '',
            cleanText: 'Um. Dois. Três. Quatro. Cinco. Seis.',
          ),
        ],
      );
      final queue = CircularAudioBuffer(maxItems: 2);

      final items = await orchestrator
          .processChapterStream(
            book: book,
            chapter: book.chapters.first,
            queue: queue,
          )
          .toList()
          .timeout(const Duration(seconds: 5));

      expect(items, hasLength(6));
      expect(queue.isCompleted, isTrue);
      queue.dispose();
    });

    test('marca a fila completa quando a síntese falha', () async {
      final failingEngine = FailingMockTTSEngine();
      final failingOrchestrator = PipelineOrchestrator(engine: failingEngine);
      final book = const EpubBook(
        title: 'Livro',
        author: 'Autor',
        chapters: [
          EpubChapter(
            index: 0,
            id: 'c1',
            title: 'Capítulo',
            rawHtml: '',
            cleanText: 'Um. Dois. Três. Quatro.',
          ),
        ],
      );
      final queue = CircularAudioBuffer(maxItems: 2);

      await expectLater(
        failingOrchestrator
            .processChapterStream(
              book: book,
              chapter: book.chapters.first,
              queue: queue,
            )
            .drain<void>(),
        throwsStateError,
      );
      expect(queue.isCompleted, isTrue);
      queue.dispose();
      await failingEngine.dispose();
    });
  });
}
