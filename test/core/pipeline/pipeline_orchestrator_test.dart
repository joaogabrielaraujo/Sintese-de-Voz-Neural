import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/engine/mock_tts_engine.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_orchestrator.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_result.dart';

void main() {
  group('PipelineOrchestrator - testes unitários com MockTTSEngine', () {
    late MockTTSEngine engine;
    late PipelineOrchestrator orchestrator;

    setUp(() {
      engine = MockTTSEngine();
      orchestrator = PipelineOrchestrator(engine: engine);
    });

    tearDown(() async {
      await engine.dispose();
    });

    test(
      'Deve orquestrar o Capítulo 1 do EPUB completo e gerar relatório com RTF < 1.0',
      () async {
        const chapter = EpubChapter(
          index: 0,
          id: 'c1.xhtml',
          title: 'Capítulo 1: Introdução ao TCC',
          rawHtml:
              r'<p>Em 24/07/2026, o Dr. Matheus aprovou a 1ª versão do TCC na UEFS custando R$ 150,00.</p>',
          cleanText:
              r'Em 24/07/2026, o Dr. Matheus aprovou a 1ª versão do TCC na UEFS custando R$ 150,00.',
        );

        const book = EpubBook(
          title: 'Leitura Neural Offline',
          author: 'João Gabriel',
          chapters: [chapter],
        );

        final PipelineResult result = await orchestrator.processChapter(
          book: book,
          chapter: chapter,
        );

        expect(result.bookTitle, equals('Leitura Neural Offline'));
        expect(result.chapterTitle, equals('Capítulo 1: Introdução ao TCC'));
        expect(result.totalSentences, equals(1));
        expect(
          result.items.first.normalizedText,
          contains('vinte e quatro de julho'),
        );
        expect(result.overallRtf, lessThan(1.0));
        expect(result.isRealTime, isTrue);

        final String report = result.generateAcademicReport();
        expect(report, contains('RELATÓRIO DE DESEMPENHO DO PRIMEIRO MVP'));
        expect(report, contains('APROVADO (RTF < 1.0)'));
      },
    );
  });
}
