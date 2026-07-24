import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/nlp/tts_normalizer.dart';

void main() {
  group('TTSNormalizer - Testes de Integração End-to-End do Pipeline PLN', () {
    test('Deve normalizar frase complexa contendo data, moeda, ordinais e siglas', () {
      const String input = r'Em 24/07/2026, o Dr. Matheus apresentou a 1ª versão do TCC na UEFS custando R$ 150,00 com 100% de aprovação.';
      final String normalized = TTSNormalizer.normalize(input);

      expect(normalized, contains('vinte e quatro de julho de dois mil e vinte e seis'));
      expect(normalized, contains('Doutor Matheus'));
      expect(normalized, contains('primeira versão do T C C na U E F S'));
      expect(normalized, contains('cento e cinquenta reais'));
      expect(normalized, contains('cem por cento de aprovação'));
    });

    test('Deve remover tags HTML e caracteres de controle preservando o texto', () {
      const String htmlInput = r'<p>Texto do <b>Capítulo 1</b> com <i>R$ 5,00</i>.</p>';
      final String normalized = TTSNormalizer.normalize(htmlInput);

      expect(normalized, equals('Texto do Capítulo um com cinco reais.'));
    });

    test('Deve retornar string vazia ao receber texto em branco', () {
      expect(TTSNormalizer.normalize('   '), equals(''));
    });
  });
}
