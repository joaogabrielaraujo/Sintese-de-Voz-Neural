import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/text/abbreviation_normalizer.dart';

void main() {
  group('AbbreviationNormalizer', () {
    test('expande abreviações', () {
      final result = AbbreviationNormalizer.normalize(
        'O Dr. Matheus orienta na pág. 10.',
      );
      expect(result, contains('Doutor'));
      expect(result, contains('página'));
    });

    test('expande símbolos especiais', () {
      expect(
        AbbreviationNormalizer.normalize('A taxa foi 100% de sucesso & aprovação.'),
        contains('por cento'),
      );
    });

    test('soletra siglas conhecidas', () {
      expect(
        AbbreviationNormalizer.normalize('Projeto de TCC na UEFS.'),
        equals('Projeto de T C C na U E F S.'),
      );
    });

    test('converte numeral romano sem soletrar as letras', () {
      expect(
        AbbreviationNormalizer.normalize('Capítulo II'),
        equals('Capítulo dois'),
      );
    });

    test('normaliza palavras inteiras em maiúsculas', () {
      expect(
        AbbreviationNormalizer.normalize('A ARQUITETURA É ÚTIL.'),
        equals('A arquitetura é útil.'),
      );
    });

    test('preserva cedilha e acentos', () {
      expect(
        AbbreviationNormalizer.normalize('AÇÃO no TCC.'),
        equals('ação no T C C.'),
      );
    });
  });
}
