import '../engine/tts_engine_interface.dart';
import '../epub/epub_model.dart';
import '../nlp/tts_normalizer.dart';
import '../segmenter/sentence_model.dart';
import '../segmenter/sentence_segmenter.dart';
import 'pipeline_result.dart';

/// Fachada Orquestradora de Alto Nível da Pipeline do TCC (PipelineOrchestrator).
///
/// Encapsula todo o ciclo de vida:
/// EPUB Chapter -> Sentence Segmenter -> PLN Normalizer -> ONNX Engine -> Telemetria RTF.
class PipelineOrchestrator {
  final ITTSEngine engine;

  PipelineOrchestrator({required this.engine});

  /// Processa um capítulo completo de um livro EPUB e retorna os resultados e métricas consolidadas.
  Future<PipelineResult> processChapter({
    required EpubBook book,
    required EpubChapter chapter,
    int maxSentenceLength = 180,
  }) async {
    // 1. Garantir que a engine ONNX foi inicializada
    if (!engine.isInitialized) {
      await engine.initialize();
    }

    // 2. Fatiamento em Sentenças (Fase 3)
    final List<TextSentence> sentences = SentenceSegmenter.segment(
      chapter.cleanText,
      maxSentenceLength: maxSentenceLength,
    );

    final List<ProcessedSentenceItem> items = [];
    double accInferenceMs = 0.0;
    double accAudioSec = 0.0;

    for (final TextSentence rawSentence in sentences) {
      // 3. Normalização Gramatical PLN em PT-BR (Fase 2)
      final String normalized = TTSNormalizer.normalize(rawSentence.text);

      // 4. Inferência Neural ONNX (Fase 1)
      final synthesisResult = await engine.synthesizeWithMetrics(normalized);

      accInferenceMs += synthesisResult.metrics.inferenceTimeMs;
      accAudioSec += synthesisResult.metrics.audioDurationSeconds;

      items.add(ProcessedSentenceItem(
        rawSentence: rawSentence,
        normalizedText: normalized,
        audio: synthesisResult.audio,
        metrics: synthesisResult.metrics,
      ));
    }

    // 5. Cálculo do RTF Global do Capítulo
    final double overallRtf = accAudioSec > 0
        ? (accInferenceMs / 1000.0) / accAudioSec
        : 0.0;

    return PipelineResult(
      bookTitle: book.title,
      chapterTitle: chapter.title,
      items: items,
      totalInferenceTimeMs: accInferenceMs,
      totalAudioDurationSeconds: accAudioSec,
      overallRtf: overallRtf,
    );
  }
}
