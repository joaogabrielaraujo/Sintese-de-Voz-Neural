import 'abbreviation_normalizer.dart';
import 'currency_normalizer.dart';
import 'date_time_normalizer.dart';
import 'number_to_words.dart';

/// Pipeline Orquestrador Puramente Funcional de Normalização de Texto para TTS em PT-BR (TTS-Norm).
///
/// Transforma um texto em linguagem natural bruto (contendo números, datas, moedas, siglas e símbolos)
/// em um fluxo continuo e fluído por extenso pronto para o motor de inferência neural VITS.
class TTSNormalizer {
  /// Executa o pipeline de normalização completo no texto fornecido.
  static String normalize(String rawText) {
    if (rawText.trim().isEmpty) return '';

    // 1. Limpeza inicial de tags HTML/XHTML e caracteres de controle
    String text = _cleanHtmlAndControlChars(rawText);

    // 2. Normalização de Moedas (ex: "R$ 150,00" -> "cento e cinquenta reais")
    text = CurrencyNormalizer.normalize(text);

    // 3. Normalização de Datas e Horários (ex: "24/07/2026" -> "vinte e quatro de julho...")
    text = DateTimeNormalizer.normalize(text);

    // 4. Normalização de Numerais Ordinais (ex: "1º" -> "primeiro")
    text = NumberToWords.replaceOrdinalsInText(text);

    // 5. Normalização de Numerais Cardinais isolados (ex: "150" -> "cento e cinquenta")
    text = NumberToWords.replaceCardinalsInText(text);

    // 6. Expansão de Abreviações, Símbolos e Siglas (ex: "UEFS" -> "U E F S", "%" -> "por cento")
    text = AbbreviationNormalizer.normalize(text);

    // 7. Sanitização de Espaçamentos Duplicados e Limpeza Final
    text = _sanitizeWhitespaceAndPunctuation(text);

    return text;
  }

  static String _cleanHtmlAndControlChars(String input) {
    final RegExp htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true);
    return input.replaceAll(htmlTagRegex, ' ').replaceAll(RegExp(r'[\r\n\t]+'), ' ');
  }

  static String _sanitizeWhitespaceAndPunctuation(String input) {
    return input
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,!?:;])'), (m) => m.group(1)!)
        .trim();
  }
}
