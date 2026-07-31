import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/text/abbreviation_normalizer.dart';

void main() {
  group('AbbreviationNormalizer - Testes Unitários de Siglas e Abreviações', () {
    test('Deve expandir abreviações títulos e acadêmicas (Dr., Prof., pág.)', () {
      expect(
        AbbreviationNormalizer.normalize('O Dr. Matheus orienta na pág. 10.'),
        contains('Doutor'),
      );
      expect(
        AbbreviationNormalizer.normalize('O Dr. Matheus orienta na pág. 10.'),
        contains('página'),
      );
    });

    test('Deve expandir símbolos especiais (%, &, +)', () {
      expect(
        AbbreviationNormalizer.normalize('A taxa foi 100% de sucesso & aprovação.'),
        contains('por cento'),
      );
    });

    test('Deve espaçar foneticamente siglas em maiúsculas (UEFS, TCC)', () {
      expect(
        AbbreviationNormalizer.normalize('Projeto de TCC na UEFS.'),
        equals('Projeto de T C C na U E F S.'),
      );
    });
  });
}
