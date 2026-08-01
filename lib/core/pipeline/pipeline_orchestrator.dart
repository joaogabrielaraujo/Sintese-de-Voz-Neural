import '../engine/tts_engine_interface.dart';
import '../document/epub_model.dart';
import '../text/tts_normalizer.dart';
import '../text/phonetic_normalizer.dart';
import '../memory/circular_audio_buffer.dart';
import '../memory/sentence_audio_item.dart';
import '../text/sentence_model.dart';
import '../text/sentence_segmenter.dart';
import 'pipeline_result.dart';

/// Fachada Orquestradora de Alto Nível da Pipeline do TCC (PipelineOrchestrator).
///
/// Encapsula todo o ciclo de vida:
/// EPUB Chapter -> Sentence Segmenter -> PLN Normalizer -> ONNX Engine -> FIFO Streaming -> Telemetria RTF.
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
      final String normalized = PhoneticNormalizer.prepare(
        TTSNormalizer.normalize(rawSentence.text),
      );

      // 4. Inferência Neural ONNX (Fase 1)
      final synthesisResult = await engine.synthesizeWithMetrics(normalized);

      accInferenceMs += synthesisResult.metrics.inferenceTimeMs;
      accAudioSec += synthesisResult.metrics.audioDurationSeconds;

      items.add(
        ProcessedSentenceItem(
          rawSentence: rawSentence,
          normalizedText: normalized,
          audio: synthesisResult.audio,
          metrics: synthesisResult.metrics,
        ),
      );
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

  /// Processa um capítulo de um livro EPUB em modo Streaming Assíncrono (Produtor FIFO).
  ///
  /// Emite cada [SentenceAudioItem] imediatamente após sua inferência para permitir
  /// reprodução com Time-To-First-Audio (TTFA < 300ms), enfileirando na [CircularAudioBuffer] (se fornecida).
  Stream<SentenceAudioItem> processChapterStream({
    required EpubBook book,
    required EpubChapter chapter,
    CircularAudioBuffer? queue,
    int maxSentenceLength = 180,
    int startSentenceIndex = 0,
  }) async* {
    if (queue == null) {
      yield* _synthesizeChapterStream(
        chapter: chapter,
        maxSentenceLength: maxSentenceLength,
        startSentenceIndex: startSentenceIndex,
      );
      return;
    }

    Object? producerError;
    StackTrace? producerStack;
    final producer = () async {
      try {
        await for (final item in _synthesizeChapterStream(
          chapter: chapter,
          maxSentenceLength: maxSentenceLength,
          startSentenceIndex: startSentenceIndex,
        )) {
          await queue.enqueue(item);
        }
      } catch (error, stack) {
        producerError = error;
        producerStack = stack;
      } finally {
        queue.markComplete();
      }
    }();

    while (true) {
      final item = await queue.dequeue(release: false);
      if (item == null) break;
      yield item;
    }

    await producer;
    if (producerError != null) {
      Error.throwWithStackTrace(producerError!, producerStack!);
    }
  }

  Stream<SentenceAudioItem> _synthesizeChapterStream({
    required EpubChapter chapter,
    required int maxSentenceLength,
    required int startSentenceIndex,
  }) async* {
    if (!engine.isInitialized) {
      await engine.initialize();
    }

    final List<TextSentence> sentences = SentenceSegmenter.segment(
      chapter.cleanText,
      maxSentenceLength: maxSentenceLength,
    );

    for (final TextSentence rawSentence in sentences) {
      if (rawSentence.index < startSentenceIndex) continue;
      final String normalized = PhoneticNormalizer.prepare(
        TTSNormalizer.normalize(rawSentence.text),
      );
      final synthesisResult = await engine.synthesizeWithMetrics(normalized);

      final item = SentenceAudioItem(
        rawSentence: rawSentence,
        normalizedText: normalized,
        audio: synthesisResult.audio,
        metrics: synthesisResult.metrics,
      );
      yield item;
    }
  }
}
