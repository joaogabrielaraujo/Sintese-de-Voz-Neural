import 'number_to_words.dart';

/// Conversor de valores monetários em Reais (R$) para extenso em PT-BR.
class CurrencyNormalizer {
  /// Expressão regular para capturar formatos como "R$ 150,00", "R$150.00", "R$ 1.500,50", "R$ 0,50".
  static final RegExp _currencyRegex = RegExp(
    r'R\$\s*(\d{1,3}(?:\.\d{3})*|\d+)(?:[,.](\d{2}))?',
    caseSensitive: false,
  );

  /// Converte todas as ocorrências de valores monetários `R$` em um texto para extensos em Português.
  static String normalize(String text) {
    return text.replaceAllMapped(_currencyRegex, (match) {
      final String rawInteiro = match.group(1)!.replaceAll('.', '');
      final String? rawCentavos = match.group(2);

      final int reais = int.tryParse(rawInteiro) ?? 0;
      final int centavos = rawCentavos != null ? (int.tryParse(rawCentavos) ?? 0) : 0;

      final List<String> parts = [];

      // Processar Reais
      if (reais > 0) {
        final String extensoReais = NumberToWords.cardinal(reais);
        final String moeda = (reais == 1) ? 'real' : 'reais';
        parts.add('$extensoReais $moeda');
      }

      // Processar Centavos
      if (centavos > 0) {
        final String extensoCentavos = NumberToWords.cardinal(centavos);
        final String moedaCent = (centavos == 1) ? 'centavo' : 'centavos';
        parts.add('$extensoCentavos $moedaCent');
      }

      if (parts.isEmpty) {
        return 'zero reais';
      }

      return parts.join(' e ');
    });
  }
}
