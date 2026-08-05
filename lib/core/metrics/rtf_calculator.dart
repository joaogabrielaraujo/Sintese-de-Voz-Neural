import '../audio/wav_writer.dart';

/// Módulo de Telemetria de Desempenho para Inferência Neural em Edge Computing.
///
/// Responsável pelo cálculo do Real-Time Factor (RTF) e registro de latência.
class PerformanceMetrics {
  /// Tempo gasto para executar a síntese neural em milissegundos.
  final double inferenceTimeMs;

  /// Duração do áudio sintetizado em segundos.
  final double audioDurationSeconds;

  /// Taxa do Fator de Tempo Real ($\text{RTF} = t_{\text{inferência}} / t_{\text{áudio}}$).
  final double rtf;

  const PerformanceMetrics({
    required this.inferenceTimeMs,
    required this.audioDurationSeconds,
    required this.rtf,
  });

  /// Indica se a inferência ocorreu em tempo real ($\text{RTF} < 1.0$).
  bool get isRealTime => rtf < 1.0;

  /// Retorna um relatório formatado e legível para logs e bancas acadêmicas.
  String formattedReport() {
    final String status = isRealTime ? 'FAVÓRAVEL (RTF < 1.0)' : 'ALERTA (RTF >= 1.0)';
    return '''
=====================================================
TELEMETRIA DE DESEMPENHO (PoC NEURAL CORE)
=====================================================
• Tempo de Inferência : ${inferenceTimeMs.toStringAsFixed(2)} ms (${(inferenceTimeMs / 1000).toStringAsFixed(3)} s)
• Duração do Áudio   : ${audioDurationSeconds.toStringAsFixed(2)} s
• Real-Time Factor    : ${rtf.toStringAsFixed(4)} -> Status: $status
=====================================================
''';
  }
}

/// Utilitário para rastrear e calcular métricas de execução de síntese.
class RTFCalculator {
  /// Executa um bloco de síntese assíncrono, mede o tempo de CPU/GPU e retorna as métricas junto ao resultado.
  static Future<({T result, PerformanceMetrics metrics})> trackExecution<T>({
    required Future<T> Function() action,
    required AudioBuffer Function(T result) extractAudio,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    
    final T result = await action();
    
    stopwatch.stop();
    
    final double inferenceTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
    final AudioBuffer audio = extractAudio(result);
    final double audioDurationSeconds = audio.durationInSeconds;

    final double rtf = audioDurationSeconds > 0
        ? (inferenceTimeMs / 1000.0) / audioDurationSeconds
        : 0.0;

    final PerformanceMetrics metrics = PerformanceMetrics(
      inferenceTimeMs: inferenceTimeMs,
      audioDurationSeconds: audioDurationSeconds,
      rtf: rtf,
    );

    return (result: result, metrics: metrics);
  }

  /// Calcula diretamente as métricas com base no tempo em ms e no buffer de áudio.
  static PerformanceMetrics calculate({
    required double inferenceTimeMs,
    required AudioBuffer audio,
  }) {
    final double audioDurationSeconds = audio.durationInSeconds;
    final double rtf = audioDurationSeconds > 0
        ? (inferenceTimeMs / 1000.0) / audioDurationSeconds
        : 0.0;

    return PerformanceMetrics(
      inferenceTimeMs: inferenceTimeMs,
      audioDurationSeconds: audioDurationSeconds,
      rtf: rtf,
    );
  }
}
