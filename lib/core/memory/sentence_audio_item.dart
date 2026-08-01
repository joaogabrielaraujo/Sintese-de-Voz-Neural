import 'dart:typed_data';

import '../audio/wav_writer.dart';
import '../metrics/rtf_calculator.dart';
import '../text/sentence_model.dart';

/// Item individual contendo a sentença fatiada, o texto PLN e o buffer de áudio PCM sintetizado.
class SentenceAudioItem {
  final TextSentence rawSentence;
  final String normalizedText;
  final AudioBuffer audio;
  final PerformanceMetrics metrics;

  const SentenceAudioItem({
    required this.rawSentence,
    required this.normalizedText,
    required this.audio,
    required this.metrics,
  });

  /// Duração do áudio em segundos.
  double get durationSeconds => audio.durationInSeconds;

  /// Quantidade de palavras na sentença.
  int get wordCount => rawSentence.wordCount;

  /// Converte o buffer de áudio em um array de bytes no padrão RIFF/WAV.
  Uint8List toWavBytes() {
    return WavWriter.encodeToWav(audio);
  }

  @override
  String toString() =>
      'SentenceAudioItem(#${rawSentence.index + 1}, dur: ${durationSeconds.toStringAsFixed(2)}s)';
}
