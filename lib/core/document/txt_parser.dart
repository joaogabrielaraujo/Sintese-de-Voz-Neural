import '../document/epub_model.dart';
import '../document/html_sanitizer.dart';

/// Extrator e Parser de Arquivos de Texto Puro (.txt).
///
/// Converte arquivos `.txt` em instâncias compatíveis de [EpubBook], permitindo
/// que documentos de texto sejam processados de forma idêntica a e-books na pipeline.
class TxtParser {
  /// Parseia uma String contendo o texto completo do arquivo `.txt`.
  static EpubBook parseText(
    String rawText, {
    String title = 'Documento de Texto',
    String author = 'Autor Desconhecido',
    String language = 'pt-BR',
  }) {
    final String cleanText = HtmlSanitizer.sanitize(rawText);

    final EpubChapter singleChapter = EpubChapter(
      index: 1,
      id: 'txt_chapter_1',
      title: title,
      rawHtml: rawText,
      cleanText: cleanText,
    );

    return EpubBook(
      title: title,
      author: author,
      language: language,
      chapters: [singleChapter],
    );
  }
}
