import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/nlp/currency_normalizer.dart';

void main() {
  group(r'CurrencyNormalizer - Testes Unitários de Moeda (Reais R$)', () {
    test(r'Deve converter valores inteiros de reais (ex: R$ 150,00)', () {
      expect(
        CurrencyNormalizer.normalize(r'O valor é R$ 150,00 no Pix.'),
        equals('O valor é cento e cinquenta reais no Pix.'),
      );
    });

    test(r'Deve converter valores com centavos (ex: R$ 1,50)', () {
      expect(
        CurrencyNormalizer.normalize(r'Custou R$ 1,50.'),
        equals('Custou um real e cinquenta centavos.'),
      );
    });

    test(r'Deve converter apenas centavos (ex: R$ 0,50)', () {
      expect(
        CurrencyNormalizer.normalize(r'Preço de R$ 0,50.'),
        equals('Preço de cinquenta centavos.'),
      );
    });

    test(r'Deve converter valores com separadores de milhares (ex: R$ 1.500,00)', () {
      expect(
        CurrencyNormalizer.normalize(r'Total de R$ 1.500,00.'),
        equals('Total de mil e quinhentos reais.'),
      );
    });
  });
}
