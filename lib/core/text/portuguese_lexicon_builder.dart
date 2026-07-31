import 'dart:io';
import 'tts_normalizer.dart';

/// Gerador dinâmico de dicionário léxico (`lexicon.txt`) para o modelo Sherpa-ONNX VITS PT-BR.
///
/// Resolve 100% dos erros de "OOV (Out Of Vocabulary)" e "Unknown token: g" no C++.
/// Mapeia caracteres ASCII para a tabela exata de tokens do Piper VITS
/// (ex: converte 'g' ASCII U+0067 para 'ɡ' IPA U+0261).
class PortugueseLexiconBuilder {
  /// Converte uma palavra simples em tokens fonéticos/caracteres válidos para o Sherpa-ONNX.
  static String wordToTokens(String word) {
    final String cleanWord = TTSNormalizer.removeDiacritics(word.toLowerCase().trim());
    final List<String> tokens = [];

    for (int i = 0; i < cleanWord.length; i++) {
      final String char = cleanWord[i];
      if (char == 'g') {
        // Substituição crucial: ASCII 'g' (U+0067) -> IPA 'ɡ' (U+0261) presente no tokens.txt
        tokens.add('ɡ');
      } else if (RegExp(r'[a-z0-9ç]').hasMatch(char)) {
        tokens.add(char);
      }
    }

    return tokens.join(' ');
  }

  /// Gera o conteúdo completo formatado do arquivo lexicon.txt para um conjunto de palavras.
  static String generateLexiconContent(Iterable<String> words) {
    final Map<String, String> lexiconEntries = {};

    // Palavras fundamentais padrão do vocabulário
    final List<String> defaultWords = [
      'capitulo', 'fundamentacao', 'objetivos', 'em', 'vinte', 'quatro', 'de',
      'julho', 'dois', 'mil', 'seis', 'doutor', 'matheus', 'aprovou', 'primeira',
      'versao', 'do', 'tcc', 'na', 'uefs', 'custando', 'cento', 'cinquenta',
      'reais', 'com', 'cem', 'por', 'aprovacao', 'sintese', 'voz', 'neural',
      'opera', 'offline', 'no', 'dispositivo', 'movel', 'rtf', 'esta', 'arquitetura',
      'garante', 'consumo', 'constante', 'memoria', 'ram', 'um', 'dois', 'tres',
      'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove', 'dez', 'zero', 'os',
      'modulos', 'core', 'foram', 'desenvolvidos', 'dart', 'divididos', 'camadas',
      'desacopladas', 'modular', 'leitura', 'livro', 'pagina', 'texto', 'audio',
      'execucao', 'tempo', 'real', 'processamento', 'fundamentos', 'pesquisa'
    ];

    final Set<String> allWords = {...defaultWords};

    for (final rawWord in words) {
      final String clean = TTSNormalizer.removeDiacritics(rawWord.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9ç]'), ''));
      if (clean.isNotEmpty) {
        allWords.add(clean);
      }
    }

    // Adicionar também o alfabeto individual para cobrir qualquer letra solta
    for (int c = 97; c <= 122; c++) {
      final char = String.fromCharCode(c);
      allWords.add(char);
    }
    for (int n = 0; n <= 9; n++) {
      allWords.add(n.toString());
    }

    final List<String> sortedWords = allWords.toList()..sort();

    final StringBuffer buffer = StringBuffer();
    for (final word in sortedWords) {
      final String tokens = wordToTokens(word);
      if (tokens.isNotEmpty) {
        lexiconEntries[word] = tokens;
        buffer.writeln('$word\t$tokens');
      }
    }

    return buffer.toString();
  }

  /// Constrói e atualiza o arquivo lexicon.txt no disco com base em um texto bruto de capítulo.
  static Future<File> buildLexiconFileForText({
    required String text,
    required String targetPath,
  }) async {
    final RegExp wordRegExp = RegExp(r'[a-zA-Z0-9çáàâãéèêíïóôõöúçñÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇÑ]+');
    final Iterable<Match> matches = wordRegExp.allMatches(text);
    final Set<String> words = matches.map((m) => TTSNormalizer.removeDiacritics(m.group(0)!.toLowerCase())).toSet();

    final String content = generateLexiconContent(words);
    final File lexiconFile = File(targetPath);
    await lexiconFile.writeAsString(content, flush: true);
    return lexiconFile;
  }
}
