import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/mock_tts_engine.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_orchestrator.dart';
import 'package:tcc_tts_neural/core/memory/circular_audio_buffer.dart';

void main() {
  group('Large Book Memory Stress Test & OOM Prevention (Fase 8)', () {
    late MockTTSEngine engine;
    late PipelineOrchestrator orchestrator;

    setUp(() {
      engine = MockTTSEngine(
        config: TTSConfig.defaultPtBr(),
        msPerCharacter: 0.0, // Síntese mock instantânea para o teste de estresse
      );
      orchestrator = PipelineOrchestrator(engine: engine);
    });

    tearDown(() {
      engine.dispose();
    });

    test(
      'Leitura de capítulo com 500 sentenças (~10.000 palavras) mantém consumo de RAM plano < 50MB',
      () async {
      // Gera texto contínuo de 500 sentenças (~10.000 palavras)
      final String largeChapterText = List.generate(
        500,
        (i) => 'Esta é a sentença número ${i + 1} do teste de estresse de memória RAM do TCC na UEFS.',
      ).join(' ');

      final book = EpubBook(
        title: 'Livro Extenso de Teste de Carga',
        author: 'João Gabriel A. Almeida',
        chapters: [
          EpubChapter(
            index: 0,
            id: 'large_chap',
            title: 'Capítulo Extenso de Carga',
            rawHtml: '<p>$largeChapterText</p>',
            cleanText: largeChapterText,
          ),
        ],
      );

      final queue = CircularAudioBuffer(maxItems: 5);
      double maxRamObservedMb = 0.0;
      int totalItemsProcessed = 0;

      // Inicia a produção em background
      final stream = orchestrator.processChapterStream(
        book: book,
        chapter: book.chapters.first,
        queue: queue,
      );

      // Consumidor em paralelo desempilhando a fila conforme produzida
      final consumerFuture = Future(() async {
        while (totalItemsProcessed < 500) {
          final item = await queue.dequeue();
          if (item != null) {
            totalItemsProcessed++;
            final currentRamMb = queue.memoryManager.stats.allocatedMb;
            if (currentRamMb > maxRamObservedMb) {
              maxRamObservedMb = currentRamMb;
            }
          }
        }
      });

      await Future.wait([stream.drain(), consumerFuture]);

      expect(totalItemsProcessed, equals(500));
      expect(queue.isCompleted, isTrue);

      // A pegada máxima de memória RAM alocada em qualquer momento deve ser mantida estritamente abaixo do limite de 50.0 MB
      expect(maxRamObservedMb, lessThan(50.0));
      // No final do capítulo longo, a RAM alocada é zerada (purge total)
      expect(queue.memoryManager.stats.allocatedBytes, equals(0));
      expect(queue.memoryManager.stats.purgedItemsCount, equals(500));

      queue.dispose();
    },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
