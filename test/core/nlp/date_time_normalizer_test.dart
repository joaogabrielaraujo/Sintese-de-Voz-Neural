import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/nlp/date_time_normalizer.dart';

void main() {
  group('DateTimeNormalizer - Testes Unitários de Datas e Horas', () {
    test('Deve converter datas no formato DD/MM/AAAA', () {
      expect(
        DateTimeNormalizer.normalize('Defesa em 24/07/2026.'),
        equals('Defesa em vinte e quatro de julho de dois mil e vinte e seis.'),
      );
    });

    test('Deve converter dia primeiro (1º de determinado mês)', () {
      expect(
        DateTimeNormalizer.normalize('Reunião em 01/05/2026.'),
        equals('Reunião em primeiro de maio de dois mil e vinte e seis.'),
      );
    });

    test('Deve converter horários no formato HH:MM e HHhMM', () {
      expect(
        DateTimeNormalizer.normalize('Aula às 14:30 na universidade.'),
        equals('Aula às quatorze horas e trinta minutos na universidade.'),
      );

      expect(
        DateTimeNormalizer.normalize('Início às 08h00.'),
        equals('Início às oito horas.'),
      );
    });
  });
}
