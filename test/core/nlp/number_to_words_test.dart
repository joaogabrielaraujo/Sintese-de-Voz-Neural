import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/nlp/number_to_words.dart';

void main() {
  group('NumberToWords - Testes Unitários de Numerais Cardinais e Ordinais', () {
    test('Deve converter números cardinais simples de 0 a 19', () {
      expect(NumberToWords.cardinal(0), equals('zero'));
      expect(NumberToWords.cardinal(1), equals('um'));
      expect(NumberToWords.cardinal(10), equals('dez'));
      expect(NumberToWords.cardinal(15), equals('quinze'));
      expect(NumberToWords.cardinal(19), equals('dezenove'));
    });

    test('Deve converter dezenas e centenas', () {
      expect(NumberToWords.cardinal(20), equals('vinte'));
      expect(NumberToWords.cardinal(35), equals('trinta e cinco'));
      expect(NumberToWords.cardinal(100), equals('cem'));
      expect(NumberToWords.cardinal(150), equals('cento e cinquenta'));
      expect(NumberToWords.cardinal(500), equals('quinhentos'));
    });

    test('Deve converter milhares e milhões (ex: ano de 2026)', () {
      expect(NumberToWords.cardinal(1000), equals('mil'));
      expect(NumberToWords.cardinal(2026), equals('dois mil e vinte e seis'));
      expect(NumberToWords.cardinal(1000000), equals('um milhão'));
    });

    test('Deve converter numerais ordinais masculinos e femininos', () {
      expect(NumberToWords.ordinal(1), equals('primeiro'));
      expect(NumberToWords.ordinal(1, isFeminine: true), equals('primeira'));
      expect(NumberToWords.ordinal(10), equals('décimo'));
      expect(NumberToWords.ordinal(25, isFeminine: true), equals('vigésima quinta'));
    });

    test('Deve substituir ordinais e cardinais em frases completas', () {
      expect(
        NumberToWords.replaceOrdinalsInText('O 1º capítulo da 2ª edição.'),
        equals('O primeiro capítulo da segunda edição.'),
      );

      expect(
        NumberToWords.replaceCardinalsInText('Temos 150 alunos em 2026.'),
        equals('Temos cento e cinquenta alunos em dois mil e vinte e seis.'),
      );
    });
  });
}
