import 'package:flutter/foundation.dart';

import '../audio/wav_writer.dart';
import '../audio/punctuation_pause_helper.dart';
import '../metrics/rtf_calculator.dart';
import '../text/sentence_model.dart';

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

class AudioTimelineEntry {
  final Duration start;
  final Duration speechEnd;
  final Duration end;

  const AudioTimelineEntry({
    required this.start,
    required this.speechEnd,
    required this.end,
  });
}

class _CombinedAudio {
  final AudioBuffer audio;
  final List<AudioTimelineEntry> timeline;

  const _CombinedAudio(this.audio, this.timeline);
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

  late final _CombinedAudio _combinedAudio = _combineItems(items);

  PipelineResult({
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
  int get totalWords =>
      items.fold(0, (sum, item) => sum + item.rawSentence.wordCount);

  List<AudioTimelineEntry> get timeline =>
      List<AudioTimelineEntry>.unmodifiable(_combinedAudio.timeline);

  /// Codifica e concatena todos os áudios Float32 das sentenças em um único buffer WAV com pausas naturais de 350ms.
  Uint8List get combinedWavBytes {
    return WavWriter.encodeToWav(_combinedAudio.audio);
  }

  static _CombinedAudio _combineItems(List<ProcessedSentenceItem> items) {
    final List<double> allSamples = [];
    int sampleRate = 22050;
    int numChannels = 1;
    final timeline = <AudioTimelineEntry>[];
    if (items.isNotEmpty) {
      sampleRate = items.first.audio.sampleRate;
      numChannels = items.first.audio.numChannels;
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.audio.sampleRate != sampleRate ||
            item.audio.numChannels != numChannels) {
          throw StateError(
            'Cannot combine audio with different sample rates or channel layouts.',
          );
        }
        if (item.audio.samples.length % numChannels != 0) {
          throw StateError('Audio item contains an incomplete channel frame.');
        }

        final startFrame = allSamples.length ~/ numChannels;
        allSamples.addAll(item.audio.samples);
        final speechEndFrame = allSamples.length ~/ numChannels;

        if (i < items.length - 1) {
          final pauseMs = PunctuationPauseHelper.pauseAfterTextMs(
            item.rawSentence.text,
          );
          final int pauseFrames = (sampleRate * pauseMs / 1000).round();
          allSamples.addAll(
            List<double>.filled(pauseFrames * numChannels, 0.0),
          );
        }
        final endFrame = allSamples.length ~/ numChannels;
        timeline.add(
          AudioTimelineEntry(
            start: _framesToDuration(startFrame, sampleRate),
            speechEnd: _framesToDuration(speechEndFrame, sampleRate),
            end: _framesToDuration(endFrame, sampleRate),
          ),
        );
      }
    }
    final combinedBuffer = AudioBuffer(
      samples: Float32List.fromList(allSamples),
      sampleRate: sampleRate,
      numChannels: numChannels,
    );
    return _CombinedAudio(combinedBuffer, timeline);
  }

  static Duration _framesToDuration(int frames, int sampleRate) {
    return Duration(
      microseconds: (frames * Duration.microsecondsPerSecond / sampleRate)
          .round(),
    );
  }

  /// Indica se o desempenho atendeu o requisito de tempo real ($\text{RTF} < 1.0$).
  bool get isRealTime => overallRtf < 1.0;

  /// Gera o relatório sintético formatado para o orientador do TCC.
  String generateAcademicReport() {
    final String status = isRealTime
        ? 'APROVADO (RTF < 1.0)'
        : 'REQUER OTIMIZAÇÃO (RTF >= 1.0)';
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
  String toString() =>
      'PipelineResult(book: "$bookTitle", RTF: ${overallRtf.toStringAsFixed(4)})';
}
