import '../document/epub_model.dart';
import '../document/html_sanitizer.dart';

/// Sanitizador e Extrator de Texto de Documentos PDF (.pdf).
///
/// Remove marcas d'água, números de página ("Página X", "Page X"), cabeçalhos e rodapés,
/// convertendo o fluxo em instâncias imutáveis de [EpubBook].
class PdfParser {
  /// Higieniza o texto extraído de um documento PDF, removendo ruídos de cabeçalhos e números de página.
  static String sanitizePdfText(String rawPdfText) {
    String text = HtmlSanitizer.sanitize(rawPdfText);

    // Remover marcadores de número de página comuns em PDFs (ex: "Página 12", "Page 5", "- 4 -")
    text = text.replaceAll(RegExp(r'p[áa]gina\s+\d+', caseSensitive: false, multiLine: true), '');
    text = text.replaceAll(RegExp(r'page\s+\d+', caseSensitive: false, multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*-\s*\d+\s*-\s*$', multiLine: true), '');

    // Normalizar quebras de linha excessivas
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Parseia o texto higienizado de um PDF para [EpubBook].
  static EpubBook parsePdfText(
    String rawPdfText, {
    String title = 'Documento PDF',
    String author = 'Autor Desconhecido',
    String language = 'pt-BR',
  }) {
    final String cleanText = sanitizePdfText(rawPdfText);

    final EpubChapter chapter = EpubChapter(
      index: 1,
      id: 'pdf_chapter_1',
      title: title,
      rawHtml: rawPdfText,
      cleanText: cleanText,
    );

    return EpubBook(
      title: title,
      author: author,
      language: language,
      chapters: [chapter],
    );
  }
}
