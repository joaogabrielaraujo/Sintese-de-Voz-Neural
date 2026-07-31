import 'package:flutter/foundation.dart';

/// Modelo de dados imutável representando um capítulo extraído de um arquivo EPUB.
@immutable
class EpubChapter {
  /// Índice sequencial do capítulo na ordem de leitura (Spine).
  final int index;

  /// Identificador do elemento ou arquivo no manifesto (ex: "chapter1.xhtml").
  final String id;

  /// Título do capítulo extraído do cabeçalho HTML ou do manifesto.
  final String title;

  /// Conteúdo bruto em XHTML/HTML do capítulo.
  final String rawHtml;

  /// Texto limpo e sanitizado por extenso, livre de tags HTML.
  final String cleanText;

  const EpubChapter({
    required this.index,
    required this.id,
    required this.title,
    required this.rawHtml,
    required this.cleanText,
  });

  /// Contagem total de palavras no capítulo limpo.
  int get wordCount => cleanText.trim().isEmpty ? 0 : cleanText.trim().split(RegExp(r'\s+')).length;

  /// Alias para o texto limpo do capítulo.
  String get plainText => cleanText;

  /// Contagem total de caracteres.
  int get characterCount => cleanText.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpubChapter &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          id == other.id &&
          title == other.title &&
          cleanText == other.cleanText;

  @override
  int get hashCode => index.hashCode ^ id.hashCode ^ title.hashCode ^ cleanText.hashCode;

  @override
  String toString() {
    return 'EpubChapter(#$index "$title", words: $wordCount, chars: $characterCount)';
  }
}

/// Modelo de dados imutável representando um livro digital EPUB completo.
@immutable
class EpubBook {
  /// Título do livro extraído dos metadados OPF.
  final String title;

  /// Nome do autor/criador.
  final String author;

  /// Idioma (ex: "pt-BR", "pt").
  final String language;

  /// Lista imutável de capítulos organizados na ordem de leitura (Spine).
  final List<EpubChapter> chapters;

  const EpubBook({
    required this.title,
    required this.author,
    this.language = 'pt-BR',
    required this.chapters,
  });

  /// Quantidade total de capítulos no livro.
  int get totalChapters => chapters.length;

  /// Retorna o Capítulo 1 do livro ou o primeiro capítulo não-vazio disponível.
  EpubChapter? get chapterOne {
    if (chapters.isEmpty) return null;
    return chapters.firstWhere(
      (chap) => chap.cleanText.trim().isNotEmpty,
      orElse: () => chapters.first,
    );
  }

  /// Retorna o total acumulado de palavras do livro.
  int get totalWords => chapters.fold(0, (sum, chap) => sum + chap.wordCount);

  @override
  String toString() {
    return 'EpubBook("$title" por $author, capítulos: $totalChapters, totalWords: $totalWords)';
  }
}
