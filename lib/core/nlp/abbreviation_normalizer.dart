/// Expansor de siglas, abreviações comuns e símbolos especiais em PT-BR.
class AbbreviationNormalizer {
  static const Map<String, String> _abbreviations = {
    'Dr.': 'Doutor',
    'Dra.': 'Doutora',
    'Prof.': 'Professor',
    'Profa.': 'Professora',
    'Sr.': 'Senhor',
    'Sra.': 'Senhora',
    'pág.': 'página',
    'págs.': 'páginas',
    'p.': 'página',
    'cap.': 'capítulo',
    'caps.': 'capítulos',
    'vol.': 'volume',
    'ed.': 'edição',
    'etc.': 'etcétera',
    'ex.': 'exemplo',
    'art.': 'artigo',
  };

  static const Map<String, String> _symbols = {
    '%': 'por cento',
    '&': 'e',
    '+': 'mais',
    '=': 'igual a',
    '@': 'arroba',
    '#': 'hashtag',
  };

  /// Expressão regular para identificar siglas em maiúsculas (ex: "UEFS", "ONNX", "TCC", "WAV").
  static final RegExp _siglaRegex = RegExp(r'\b[A-Z]{2,6}\b');

  /// Expande abreviações, símbolos e siglas em um texto.
  static String normalize(String text) {
    String result = text;

    // 1. Substituição de Abreviações
    _abbreviations.forEach((pattern, replacement) {
      final String escapedPattern = RegExp.escape(pattern);
      final RegExp regex = RegExp('(?<=\\s|^)$escapedPattern(?=\\s|\$|\\,|\\.)');
      result = result.replaceAll(regex, replacement);
    });

    // 2. Substituição de Símbolos Especiais
    _symbols.forEach((symbol, replacement) {
      result = result.replaceAll(symbol, ' $replacement ');
    });

    // 3. Expansão Fonética de Siglas (ex: "UEFS" -> "U E F S")
    result = result.replaceAllMapped(_siglaRegex, (match) {
      final String sigla = match.group(0)!;
      return sigla.split('').join(' ');
    });

    return result;
  }
}
