import 'package:flutter/foundation.dart';

import '../audio/wav_writer.dart';
import '../metrics/rtf_calculator.dart';
import '../segmenter/sentence_model.dart';

/// Item processado individualmente na pipeline contendo a sentença bruta, texto PLN e métricas.
class ProcessedSentenceItem {
  final TextSentence rawSentence;
  final String normalizedText;
  final AudioBuffer audio;
  final PerformanceMetrics metrics;

  const ProcessedSentenceItem({
    required this.rawSentence,
    required this.normalizedText,
    required this.audio,
    required this.metrics,
  });
}

/// Modelo de dados imutável com a telemetria consolidada da execução do MVP.
@immutable
class PipelineResult {
  /// Título do livro EPUB.
  final String bookTitle;

  /// Título do capítulo processado.
  final String chapterTitle;

  /// Lista de itens processados por sentença.
  final List<ProcessedSentenceItem> items;

  /// Tempo total acumulado de inferência em milissegundos.
  final double totalInferenceTimeMs;

  /// Duração total acumulada do áudio gerado em segundos.
  final double totalAudioDurationSeconds;

  /// Fator de Tempo Real Global ($\text{RTF} = t_{\text{inferência}} / t_{\text{áudio}}$).
  final double overallRtf;

  const PipelineResult({
    required this.bookTitle,
    required this.chapterTitle,
    required this.items,
    required this.totalInferenceTimeMs,
    required this.totalAudioDurationSeconds,
    required this.overallRtf,
  });

  /// Total de sentenças processadas.
  int get totalSentences => items.length;

  /// Total de palavras no capítulo.
  int get totalWords => items.fold(0, (sum, item) => sum + item.rawSentence.wordCount);

  /// Indica se o desempenho atendeu o requisito de tempo real ($\text{RTF} < 1.0$).
  bool get isRealTime => overallRtf < 1.0;

  /// Gera o relatório sintético formatado para o orientador do TCC.
  String generateAcademicReport() {
    final String status = isRealTime ? 'APROVADO (RTF < 1.0)' : 'REQUER OTIMIZAÇÃO (RTF >= 1.0)';
    return '''
=====================================================================
🎓 RELATÓRIO DE DESEMPENHO DO PRIMEIRO MVP - TCC SÍNTESE NEURAL (UEFS)
=====================================================================
• Livro Processado     : $bookTitle
• Capítulo             : $chapterTitle
• Total de Sentenças   : $totalSentences
• Total de Palavras    : $totalWords
---------------------------------------------------------------------
• Tempo Total CPU/ONNX : ${totalInferenceTimeMs.toStringAsFixed(2)} ms (${(totalInferenceTimeMs / 1000).toStringAsFixed(3)} s)
• Duração do Áudio WAV : ${totalAudioDurationSeconds.toStringAsFixed(2)} s
• Real-Time Factor (RTF): ${overallRtf.toStringAsFixed(4)}
---------------------------------------------------------------------
📌 STATUS DO REQUISITO RNF-02 (Tempo Real): $status
=====================================================================
''';
  }

  @override
  String toString() => 'PipelineResult(book: "$bookTitle", RTF: ${overallRtf.toStringAsFixed(4)})';
}
