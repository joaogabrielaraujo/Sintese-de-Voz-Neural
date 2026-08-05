import '../memory/sentence_audio_item.dart';

class StreamingSentenceMetrics {
  final int index;
  final String text;
  final Duration audioDuration;
  final Duration synthesisDuration;

  const StreamingSentenceMetrics({
    required this.index,
    required this.text,
    required this.audioDuration,
    required this.synthesisDuration,
  });

  double get rtf {
    final audioSec = audioDuration.inMicroseconds / 1000000.0;
    final synthSec = synthesisDuration.inMicroseconds / 1000000.0;
    if (audioSec == 0) return 0.0;
    return synthSec / audioSec;
  }
}

class StreamingTelemetrySnapshot {
  final List<StreamingSentenceMetrics> items;
  final int currentQueueLength;
  final int maxQueueCapacity;
  final double estimatedMemoryMb;

  const StreamingTelemetrySnapshot({
    required this.items,
    this.currentQueueLength = 0,
    this.maxQueueCapacity = 3,
    this.estimatedMemoryMb = 0.0,
  });

  bool get isEmpty => items.isEmpty;

  double? get overallRtf {
    if (items.isEmpty) return null;
    double totalAudioSec = 0.0;
    double totalSynthSec = 0.0;
    for (final item in items) {
      totalAudioSec += item.audioDuration.inMicroseconds / 1000000.0;
      totalSynthSec += item.synthesisDuration.inMicroseconds / 1000000.0;
    }
    if (totalAudioSec == 0.0) return null;
    return totalSynthSec / totalAudioSec;
  }

  String generateAcademicReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== RELATÓRIO DE DESEMPENHO ACADÊMICO (TCC UEFS) ===');
    buffer.writeln('Sentenças Processadas: ${items.length}');
    final rtf = overallRtf;
    buffer.writeln('Real-Time Factor (RTF) Médio: ${rtf != null ? rtf.toStringAsFixed(3) : '—'}');
    buffer.writeln('Fila Circular: $currentQueueLength / $maxQueueCapacity');
    buffer.writeln('Uso Estimado de RAM: ${estimatedMemoryMb.toStringAsFixed(2)} MB');
    buffer.writeln('\nDetalhamento por Sentença:');
    for (final item in items) {
      buffer.writeln(
        '  #${item.index + 1}: ${item.audioDuration.inMilliseconds}ms áudio | '
        '${item.synthesisDuration.inMilliseconds}ms síntese | RTF ${item.rtf.toStringAsFixed(3)}',
      );
    }
    return buffer.toString();
  }
}

class StreamingTelemetryAccumulator {
  final List<StreamingSentenceMetrics> _items = [];
  int _currentQueueLength = 0;
  int _maxQueueCapacity = 3;

  void addAcceptedItem(SentenceAudioItem item) {
    final audioDur = Duration(microseconds: (item.audio.durationInSeconds * 1000000).round());
    final synthDur = Duration(microseconds: (item.metrics.inferenceTimeMs * 1000).round());
    _items.add(
      StreamingSentenceMetrics(
        index: item.rawSentence.index,
        text: item.rawSentence.text,
        audioDuration: audioDur,
        synthesisDuration: synthDur,
      ),
    );
  }

  void updateQueueState(int currentLength, int maxCapacity) {
    _currentQueueLength = currentLength;
    _maxQueueCapacity = maxCapacity;
  }

  void reset() {
    _items.clear();
    _currentQueueLength = 0;
  }

  StreamingTelemetrySnapshot snapshot({double memoryMb = 0.0}) {
    return StreamingTelemetrySnapshot(
      items: List.unmodifiable(_items),
      currentQueueLength: _currentQueueLength,
      maxQueueCapacity: _maxQueueCapacity,
      estimatedMemoryMb: memoryMb,
    );
  }
}
