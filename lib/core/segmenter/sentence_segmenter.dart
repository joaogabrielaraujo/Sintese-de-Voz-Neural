import 'sentence_model.dart';

/// Fatiador Puramente Funcional de Sentenças para Processamento de Livros e Capítulos (Sentence Segmenter).
///
/// Fragmenta textos contínuos em uma sequência de [TextSentence], protegendo abreviações,
/// respeitando diálogos e dividindo suavemente frases demasiadamente longas.
class SentenceSegmenter {
  /// Lista de abreviações conhecidas que NÃO devem causar quebra de sentença.
  static final Set<String> _abbreviations = {
    'dr', 'dra', 'prof', 'profa', 'sr', 'sra', 'pag', 'pág', 'pags', 'págs', 'p',
    'cap', 'caps', 'vol', 'ed', 'etc', 'ex', 'art', 'av', 'al', 'op'
  };

  /// Fatiamento principal de um texto de entrada.
  ///
  /// [text]: O texto bruto ou limpo do capítulo.
  /// [maxSentenceLength]: Limite de caracteres recomendado por sentença para a engine neural (padrão: 180).
  static List<TextSentence> segment(
    String text, {
    int maxSentenceLength = 180,
  }) {
    if (text.trim().isEmpty) return [];

    final List<TextSentence> result = [];
    int sentenceCounter = 0;

    // 1. Dividir em parágrafos por quebras de linha duplas \n\n ou \r\n\r\n
    final List<String> rawParagraphs = text
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n+'));

    for (final String paragraph in rawParagraphs) {
      final String trimmedParagraph = paragraph.trim();
      if (trimmedParagraph.isEmpty) continue;

      // 2. Extrair sentenças do parágrafo
      final List<String> rawSentences = _segmentParagraph(trimmedParagraph, maxSentenceLength);

      for (int i = 0; i < rawSentences.length; i++) {
        final String sentenceText = rawSentences[i].trim();
        if (sentenceText.isEmpty) continue;

        final bool isLastInParagraph = (i == rawSentences.length - 1);

        result.add(TextSentence(
          index: sentenceCounter++,
          text: sentenceText,
          isParagraphEnd: isLastInParagraph,
        ));
      }
    }

    return result;
  }

  static List<String> _segmentParagraph(String paragraph, int maxLength) {
    final List<String> sentences = [];
    final List<String> currentWords = [];

    final List<String> words = paragraph.split(RegExp(r'\s+'));

    for (int i = 0; i < words.length; i++) {
      final String word = words[i];
      currentWords.add(word);

      final String currentText = currentWords.join(' ');

      if (_isSentenceEndingWord(word)) {
        if (!_isAbbreviationWord(word)) {
          sentences.add(currentText);
          currentWords.clear();
        }
      } else if (currentText.length >= maxLength) {
        final List<String> softSplit = _softSplitLongSentence(currentText, maxLength);
        if (softSplit.length > 1) {
          sentences.addAll(softSplit.sublist(0, softSplit.length - 1));
          currentWords.clear();
          currentWords.addAll(softSplit.last.split(RegExp(r'\s+')));
        }
      }
    }

    if (currentWords.isNotEmpty) {
      sentences.add(currentWords.join(' '));
    }

    return sentences;
  }

  static bool _isSentenceEndingWord(String word) {
    final String clean = word.trim();
    if (clean.isEmpty) return false;
    final String lastChar = clean[clean.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?' || clean.endsWith('...');
  }

  static bool _isAbbreviationWord(String word) {
    final String clean = word.trim();
    if (!clean.endsWith('.') || clean.endsWith('..') || clean.endsWith('!') || clean.endsWith('?')) {
      return false;
    }

    final String base = clean.substring(0, clean.length - 1).toLowerCase();
    
    // 1. Checar se a base da palavra está no conjunto de abreviações (incluindo acentuadas)
    if (_abbreviations.contains(base)) return true;

    // 2. Checar se é uma inicial de nome isolada (ex: "J.", "K.", "A.")
    if (RegExp(r'^[A-Za-z]\.$').hasMatch(clean)) return true;

    return false;
  }

  static List<String> _softSplitLongSentence(String text, int maxLength) {
    final RegExp softDelimiters = RegExp(r'(?<=[,;—–])\s+');
    final List<String> parts = text.split(softDelimiters);

    if (parts.length <= 1) return [text];

    final List<String> result = [];
    final StringBuffer buffer = StringBuffer();

    for (final String part in parts) {
      if (buffer.length + part.length > maxLength && buffer.isNotEmpty) {
        result.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write('$part ');
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString().trim());
    }

    return result;
  }
}
