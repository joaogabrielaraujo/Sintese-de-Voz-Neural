import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/engine/mock_tts_engine.dart';
import 'package:tcc_tts_neural/core/pipeline/pipeline_orchestrator.dart';

void main() {
  test('streaming começa no índice confirmado sem sintetizar o anterior', () async {
    final engine = MockTTSEngine(config: TTSConfig.defaultPtBr());
    final orchestrator = PipelineOrchestrator(engine: engine);
    const chapter = EpubChapter(
      index: 0,
      id: 'chapter',
      title: 'Capítulo',
      rawHtml: '',
      cleanText: 'Primeira. Segunda. Terceira.',
    );
    const book = EpubBook(title: 'Livro', author: 'Autor', chapters: [chapter]);

    final items = await orchestrator
        .processChapterStream(
          book: book,
          chapter: chapter,
          startSentenceIndex: 1,
        )
        .toList();

    expect(items.map((item) => item.rawSentence.index), [1, 2]);
    await engine.dispose();
  });
}
