import 'epub_model.dart';
import 'html_sanitizer.dart';

/// Extrator e Parser Puramente Funcional de Arquivos EPUB.
///
/// Responsável pela descompactação, resolução da sequência de leitura (Spine)
/// e geração do objeto imutável [EpubBook].
class EpubParser {
  /// Realiza o parsing de um mapa simulado ou descompactado de arquivos de um EPUB (caminho -> conteúdo String/Bytes).
  static EpubBook parseArchive(Map<String, String> files) {
    String title = 'Livro sem Título';
    String author = 'Autor Desconhecido';
    String language = 'pt-BR';

    // 1. Localizar o caminho do manifesto OPF em META-INF/container.xml
    final String opfPath = normalizeArchivePath(_findOpfPath(files));

    // 2. Extrair metadados e spine do arquivo OPF
    final String opfContent = files[opfPath] ?? files['content.opf'] ?? files['OEBPS/content.opf'] ?? '';

    if (opfContent.isNotEmpty) {
      title = _extractXmlTag(opfContent, 'dc:title') ?? _extractXmlTag(opfContent, 'title') ?? title;
      author = _extractXmlTag(opfContent, 'dc:creator') ?? _extractXmlTag(opfContent, 'creator') ?? author;
      language = _extractXmlTag(opfContent, 'dc:language') ?? language;
    }

    // 3. Obter a lista de capítulos (arquivos XHTML) na ordem exata de leitura
    final List<String> chapterPaths = _getChapterPathsFromOpf(opfContent, opfPath, files);

    final List<EpubChapter> chapters = [];
    int chapterIndex = 0;

    for (final String path in chapterPaths) {
      final String? rawHtml = files[path];
      if (rawHtml == null || rawHtml.trim().isEmpty) continue;

      final String cleanText = HtmlSanitizer.sanitize(rawHtml);
      if (cleanText.trim().isEmpty) continue;

      final String chapterTitle = HtmlSanitizer.extractTitle(
        rawHtml,
        fallbackTitle: 'Capítulo ${chapterIndex + 1}',
      );

      chapters.add(EpubChapter(
        index: chapterIndex++,
        id: path,
        title: chapterTitle,
        rawHtml: rawHtml,
        cleanText: cleanText,
      ));
    }

    // Se nenhum capítulo for encontrado via OPF, fazer fallback por busca de arquivos .xhtml ou .html
    if (chapters.isEmpty) {
      final List<String> htmlFiles = files.keys
          .where((k) => k.endsWith('.xhtml') || k.endsWith('.html'))
          .toList()..sort();

      for (final String path in htmlFiles) {
        final String rawHtml = files[path]!;
        final String cleanText = HtmlSanitizer.sanitize(rawHtml);
        if (cleanText.trim().isEmpty) continue;

        chapters.add(EpubChapter(
          index: chapterIndex++,
          id: path,
          title: HtmlSanitizer.extractTitle(rawHtml, fallbackTitle: 'Capítulo $chapterIndex'),
          rawHtml: rawHtml,
          cleanText: cleanText,
        ));
      }
    }

    return EpubBook(
      title: title,
      author: author,
      language: language,
      chapters: chapters,
    );
  }

  static String _findOpfPath(Map<String, String> files) {
    const String containerPath = 'META-INF/container.xml';
    if (files.containsKey(containerPath)) {
      final String content = files[containerPath]!;
      final RegExp rootfileRegex = RegExp(r'full-path="([^"]+)"', caseSensitive: false);
      final Match? match = rootfileRegex.firstMatch(content);
      if (match != null && match.group(1) != null) {
        return normalizeArchivePath(match.group(1)!);
      }
    }

    // Tentar caminhos padrão
    for (final String path in files.keys) {
      if (path.endsWith('.opf')) return normalizeArchivePath(path);
    }
    return 'EPUB/content.opf';
  }

  static List<String> _getChapterPathsFromOpf(String opfContent, String opfPath, Map<String, String> files) {
    final List<String> paths = [];
    if (opfContent.isEmpty) return paths;

    final String baseDir = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1)
        : '';

    // Mapear item IDs para hrefs no manifesto
    final Map<String, String> manifest = {};
    final RegExp itemRegex = RegExp(r'<item\s+[^>]*id="([^"]+)"[^>]*href="([^"]+)"[^>]*>', caseSensitive: false);

    for (final Match match in itemRegex.allMatches(opfContent)) {
      final String id = match.group(1)!;
      final String href = Uri.decodeFull(match.group(2)!);
      final String resolved = normalizeArchivePath(baseDir.isEmpty ? href : '$baseDir$href');
      if (resolved.isNotEmpty) manifest[id] = resolved;
    }

    // Mapear Ordem da Spine
    final RegExp itemrefRegex = RegExp(r'<itemref\s+[^>]*idref="([^"]+)"[^>]*>', caseSensitive: false);
    for (final Match match in itemrefRegex.allMatches(opfContent)) {
      final String idref = match.group(1)!;
      if (manifest.containsKey(idref)) {
        paths.add(manifest[idref]!);
      }
    }

    return paths;
  }

  /// Resolves archive paths while rejecting absolute paths and traversal.
  static String normalizeArchivePath(String path) {
    final decoded = Uri.decodeFull(path.replaceAll('\\', '/'));
    if (decoded.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(decoded)) {
      throw const FormatException('Caminho EPUB absoluto não permitido.');
    }
    final parts = <String>[];
    for (final part in decoded.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) throw const FormatException('Traversal de caminho EPUB não permitido.');
        parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return parts.join('/');
  }

  static String? _extractXmlTag(String xml, String tagName) {
    final RegExp regex = RegExp('<$tagName[^>]*>(.*?)</$tagName>', caseSensitive: false);
    final Match? match = regex.firstMatch(xml);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    return null;
  }
}
