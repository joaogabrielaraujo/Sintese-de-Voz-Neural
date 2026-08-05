import 'dart:typed_data';

import 'epub_model.dart';
import 'html_sanitizer.dart';

/// Extrator e Parser Puramente Funcional de Arquivos EPUB.
///
/// Responsável pela descompactação, resolução da sequência de leitura (Spine)
/// e geração do objeto imutável [EpubBook].
class EpubParser {
  /// Realiza o parsing de um mapa simulado ou descompactado de arquivos de um EPUB (caminho -> conteúdo String/Bytes).
  static EpubBook parseArchive(
    Map<String, String> files, {
    Map<String, Uint8List> resources = const {},
  }) {
    String title = 'Livro sem Título';
    String author = 'Autor Desconhecido';
    String language = 'pt-BR';

    // 1. Localizar o caminho do manifesto OPF em META-INF/container.xml
    final String opfPath = normalizeArchivePath(_findOpfPath(files));

    // 2. Extrair metadados e spine do arquivo OPF
    final String opfContent = files[opfPath] ?? '';
    if (opfContent.isEmpty) {
      throw const FormatException('OPF do EPUB não foi encontrado.');
    }

    if (opfContent.isNotEmpty) {
      title = _extractXmlTag(opfContent, 'dc:title') ?? _extractXmlTag(opfContent, 'title') ?? title;
      author = _extractXmlTag(opfContent, 'dc:creator') ?? _extractXmlTag(opfContent, 'creator') ?? author;
      language = _extractXmlTag(opfContent, 'dc:language') ?? language;
    }

    // 3. Obter a lista de capítulos (arquivos XHTML) na ordem exata de leitura
    final List<String> chapterPaths = _getChapterPathsFromOpf(opfContent, opfPath, files);
    final navigation = _getNavigationFromOpf(opfContent, opfPath, files);

    final List<EpubChapter> chapters = [];
    int chapterIndex = 0;

    for (final String path in chapterPaths) {
      final String? rawHtml = files[path];
      if (rawHtml == null || rawHtml.trim().isEmpty) continue;

      final blocks = _contentBlocks(rawHtml, path, resources);
      final String cleanText = blocks
          .whereType<EpubTextBlock>()
          .map((block) => block.text)
          .where((text) => text.isNotEmpty)
          .join('\n\n');
      if (cleanText.trim().isEmpty) continue;

      final nav = navigation[path];
      final String chapterTitle = nav?.title ?? HtmlSanitizer.extractTitle(
        rawHtml, fallbackTitle: 'Capítulo ${chapterIndex + 1}');

      chapters.add(EpubChapter(
        index: chapterIndex++,
        id: path,
        title: chapterTitle,
        rawHtml: rawHtml,
        cleanText: cleanText,
        contentBlocks: blocks,
        outlineLevel: nav?.level ?? 0,
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

  static Map<String, _NavigationEntry> _getNavigationFromOpf(
    String opfContent, String opfPath, Map<String, String> files) {
    final baseDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
    final manifest = <String, String>{};
    for (final match in RegExp(r'<item\b([^>]*)>', caseSensitive: false).allMatches(opfContent)) {
      final attrs = match.group(1) ?? '';
      final id = _extractAttribute(attrs, 'id');
      final href = _extractAttribute(attrs, 'href');
      if (id != null && href != null) manifest[id] = normalizeArchivePath('$baseDir${Uri.decodeFull(href).split('#').first}');
    }
    String? navPath;
    for (final match in RegExp(r'<item\b([^>]*)>', caseSensitive: false).allMatches(opfContent)) {
      final attrs = match.group(1) ?? '';
      final properties = _extractAttribute(attrs, 'properties') ?? '';
      final id = _extractAttribute(attrs, 'id');
      if (id != null && RegExp(r'(^|\s)nav(\s|$)').hasMatch(properties)) {
        navPath = manifest[id];
        break;
      }
    }
    final candidates = <String>[if (navPath != null) navPath, ...files.keys.where((path) => path.toLowerCase().endsWith('.ncx'))];
    final result = <String, _NavigationEntry>{};
    for (final candidate in candidates) {
      final content = files[candidate];
      if (content == null) continue;
      final base = candidate.contains('/') ? candidate.substring(0, candidate.lastIndexOf('/') + 1) : '';
      final link = RegExp(r'<(?:a|content)\b([^>]*)>(?:([^<]*)</a>)?', caseSensitive: false);
      var level = 0;
      for (final match in link.allMatches(content)) {
        final attrs = match.group(1) ?? '';
        final href = _extractAttribute(attrs, 'href') ?? _extractAttribute(attrs, 'src');
        if (href == null) continue;
        final path = normalizeArchivePath('$base${Uri.decodeFull(href).split('#').first}');
        final title = HtmlSanitizer.sanitize(match.group(2) ?? '').trim();
        if (title.isNotEmpty) result.putIfAbsent(path, () => _NavigationEntry(title, level));
      }
    }
    return result;
  }

  static List<EpubContentBlock> _contentBlocks(String html, String chapterPath, Map<String, Uint8List> resources) {
    final blocks = <EpubContentBlock>[];
    final image = RegExp(r'<img\b([^>]*)>', caseSensitive: false);
    var cursor = 0;
    for (final match in image.allMatches(html)) {
      final before = HtmlSanitizer.sanitize(html.substring(cursor, match.start));
      if (before.isNotEmpty) blocks.add(EpubTextBlock(before));
      final attrs = match.group(1) ?? '';
      final src = _extractAttribute(attrs, 'src');
      if (src != null) {
        final base = chapterPath.contains('/') ? chapterPath.substring(0, chapterPath.lastIndexOf('/') + 1) : '';
        final resolved = normalizeArchivePath('$base${Uri.decodeFull(src).split('#').first}');
        final bytes = resources[resolved];
        if (bytes != null) blocks.add(EpubImageBlock(resourcePath: resolved, bytes: bytes, altText: _extractAttribute(attrs, 'alt')));
      }
      cursor = match.end;
    }
    final after = HtmlSanitizer.sanitize(html.substring(cursor));
    if (after.isNotEmpty) blocks.add(EpubTextBlock(after));
    return blocks.isEmpty ? [EpubTextBlock(HtmlSanitizer.sanitize(html))] : blocks;
  }

  static String _findOpfPath(Map<String, String> files) {
    const String containerPath = 'META-INF/container.xml';
    if (files.containsKey(containerPath)) {
      final String content = files[containerPath]!;
      final RegExp rootfileRegex = RegExp(r'<rootfile\b([^>]*)>', caseSensitive: false);
      final Match? match = rootfileRegex.firstMatch(content);
      final String? fullPath = match == null
          ? null
          : _extractAttribute(match.group(1) ?? '', 'full-path');
      if (fullPath != null) {
        return normalizeArchivePath(fullPath);
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
    final RegExp itemRegex = RegExp(r'<item\b([^>]*)>', caseSensitive: false);

    for (final Match match in itemRegex.allMatches(opfContent)) {
      final attributes = match.group(1) ?? '';
      final String? id = _extractAttribute(attributes, 'id');
      final String? rawHref = _extractAttribute(attributes, 'href');
      if (id == null || rawHref == null) continue;
      final String href = Uri.decodeFull(rawHref).split('#').first;
      final String resolved = normalizeArchivePath(baseDir.isEmpty ? href : '$baseDir$href');
      if (resolved.isNotEmpty) manifest[id] = resolved;
    }

    // Mapear Ordem da Spine
    final RegExp itemrefRegex = RegExp(r'<itemref\b([^>]*)>', caseSensitive: false);
    for (final Match match in itemrefRegex.allMatches(opfContent)) {
      final String? idref = _extractAttribute(match.group(1) ?? '', 'idref');
      if (idref == null) continue;
      if (manifest.containsKey(idref)) {
        paths.add(manifest[idref]!);
      }
    }

    return paths;
  }

  /// Resolves archive paths while rejecting absolute paths and traversal.
  static String normalizeArchivePath(String path) {
    final sanitizedPath = path.replaceAll('\\', '/');
    String decoded;
    try {
      decoded = Uri.decodeFull(sanitizedPath);
    } catch (_) {
      try {
        decoded = Uri.decodeComponent(sanitizedPath);
      } catch (_) {
        decoded = sanitizedPath;
      }
    }
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

  static String? _extractAttribute(String attributes, String name) {
    final regex = RegExp(
      '\\b${RegExp.escape(name)}\\s*=\\s*["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    );
    return regex.firstMatch(attributes)?.group(1);
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

class _NavigationEntry {
  final String title;
  final int level;
  const _NavigationEntry(this.title, this.level);
}
