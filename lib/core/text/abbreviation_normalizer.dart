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

  static const Map<String, String> _romanNumerals = {
    'II': 'dois',
    'III': 'três',
    'IV': 'quatro',
    'V': 'cinco',
    'VI': 'seis',
    'VII': 'sete',
    'VIII': 'oito',
    'IX': 'nove',
    'X': 'dez',
    'XI': 'onze',
    'XII': 'doze',
    'XIII': 'treze',
    'XIV': 'catorze',
    'XV': 'quinze',
    'XVI': 'dezesseis',
    'XVII': 'dezessete',
    'XVIII': 'dezoito',
    'XIX': 'dezenove',
    'XX': 'vinte',
  };

  static const Map<String, String> _knownAcronyms = {
    'API': 'A P I',
    'CPU': 'C P U',
    'EPUB': 'E P U B',
    'HTML': 'H T M L',
    'ONNX': 'O N N X',
    'PDF': 'P D F',
    'RAM': 'R A M',
    'RTF': 'R T F',
    'TCC': 'T C C',
    'UEFS': 'U E F S',
    'WAV': 'W A V',
    'XML': 'X M L',
  };

  static final RegExp _romanRegex = RegExp(r'\b[IVXLCDM]{2,6}\b');
  static final RegExp _uppercaseWordRegex = RegExp(
    r'\b[A-ZÁÉÍÓÚÃÕÂÊÔÇÜ]{2,}\b',
  );

  /// Expande abreviações, símbolos, numerais romanos e siglas sem tratar
  /// palavras inteiras em maiúsculas como se fossem siglas.
  static String normalize(String text) {
    String result = text;

    _abbreviations.forEach((pattern, replacement) {
      final escapedPattern = RegExp.escape(pattern);
      final regex = RegExp('(?<=\\s|^)$escapedPattern(?=\\s|\$|\\,|\\.)');
      result = result.replaceAll(regex, replacement);
    });

    _symbols.forEach((symbol, replacement) {
      result = result.replaceAll(symbol, ' $replacement ');
    });

    result = result.replaceAllMapped(_romanRegex, (match) {
      final token = match.group(0)!;
      return _romanNumerals[token] ?? token.toLowerCase();
    });

    result = result.replaceAllMapped(_uppercaseWordRegex, (match) {
      final token = match.group(0)!;
      return _knownAcronyms[token] ?? token.toLowerCase();
    });
    result = result.replaceAll(RegExp(r'\bÉ\b'), 'é');

    return result;
  }
}
