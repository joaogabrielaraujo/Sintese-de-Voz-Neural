import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/pipeline/streaming_telemetry.dart';

void main() {
  group('Telemetry Flow & Academic Report', () {
    test('academic report contains required metadata header and sentence details', () {
      final accumulator = StreamingTelemetryAccumulator();
      final snapshot = accumulator.snapshot(memoryMb: 15.2);

      final report = snapshot.generateAcademicReport();
      expect(report.contains('RELATÓRIO DE DESEMPENHO ACADÊMICO'), isTrue);
      expect(report.contains('Uso Estimado de RAM: 15.20 MB'), isTrue);
    });
  });
}
