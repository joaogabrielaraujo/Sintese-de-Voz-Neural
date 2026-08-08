import 'dart:typed_data';

import 'epub_model.dart';
import 'html_sanitizer.dart';

/// Entry de navegação do sumário EPUB (NAV / NCX).
class NavigationEntry {
  final String title;
  final String path;
  final String? anchor;
  final int level;

  const NavigationEntry({
    required this.title,
    required this.path,
    this.anchor,
    this.level = 0,
  });
}

/// Extrator e Parser Puramente Funcional de Arquivos EPUB com Suporte Avançado a Sumários e Seções.
///
/// Responsável por:
/// 1. Localização e parsing do pacote OPF (metadados e leitura Spine).
/// 2. Mapeamento hierárquico do sumário (EPUB 3 nav.xhtml e EPUB 2 toc.ncx).
/// 3. Divisão precisa de capítulos por âncoras de sumário (`#id`), tags de seção (`<section>`) ou cabeçalhos HTML (`<h1>`, `<h2>`).
class EpubParser {
  /// Realiza o parsing de um mapa de arquivos de um EPUB descompactado.
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

    title = _extractXmlTag(opfContent, 'dc:title') ?? _extractXmlTag(opfContent, 'title') ?? title;
    author = _extractXmlTag(opfContent, 'dc:creator') ?? _extractXmlTag(opfContent, 'creator') ?? author;
    language = _extractXmlTag(opfContent, 'dc:language') ?? language;

    // 3. Obter a ordem dos arquivos XHTML no Spine e as entradas detalhadas do sumário
    final List<String> chapterPaths = _getChapterPathsFromOpf(opfContent, opfPath, files);
    final List<NavigationEntry> navEntries = _getNavigationEntries(opfContent, opfPath, files);

    // Mapear entradas do sumário organizadas por caminho do arquivo
    final Map<String, List<NavigationEntry>> navByPath = {};
    for (final entry in navEntries) {
      navByPath.putIfAbsent(entry.path, () => []).add(entry);
    }

    final List<EpubChapter> chapters = [];
    int globalIndex = 0;

    for (final String path in chapterPaths) {
      final String? rawHtml = files[path];
      if (rawHtml == null || rawHtml.trim().isEmpty) continue;

      final entriesForPath = navByPath[path] ?? [];
      final List<_SubSection> subSections = _extractSubSections(rawHtml, path, entriesForPath);

      for (final sub in subSections) {
        final blocks = _contentBlocks(sub.htmlContent, path, resources);
        final String cleanText = blocks
            .whereType<EpubTextBlock>()
            .map((b) => b.text)
            .where((t) => t.isNotEmpty)
            .join('\n\n');

        if (cleanText.trim().isEmpty) continue;

        chapters.add(EpubChapter(
          index: globalIndex++,
          id: sub.id,
          title: sub.title,
          rawHtml: sub.htmlContent,
          cleanText: cleanText,
          contentBlocks: blocks,
          outlineLevel: sub.level,
        ));
      }
    }

    // Se nenhum capítulo for encontrado via OPF, fazer fallback por busca direta de arquivos .xhtml / .html
    if (chapters.isEmpty) {
      final List<String> htmlFiles = files.keys
          .where((k) => k.endsWith('.xhtml') || k.endsWith('.html'))
          .toList()..sort();

      for (final String path in htmlFiles) {
        final String rawHtml = files[path]!;
        final String cleanText = HtmlSanitizer.sanitize(rawHtml);
        if (cleanText.trim().isEmpty) continue;

        chapters.add(EpubChapter(
          index: globalIndex++,
          id: path,
          title: HtmlSanitizer.extractTitle(rawHtml, fallbackTitle: 'Capítulo ${globalIndex}'),
          rawHtml: rawHtml,
          cleanText: cleanText,
        ));
      }
    }

    final Uint8List? coverBytes = _extractCoverImage(opfContent, opfPath, resources);

    return EpubBook(
      title: title,
      author: author,
      language: language,
      chapters: chapters,
      coverImageBytes: coverBytes,
    );
  }

  /// Extrai sub-seções de um arquivo HTML dividindo por âncoras do sumário (`#id`)
  /// ou, na ausência delas, por tags estruturais (`<section>`, `<h1>`, `<h2>`).
  static List<_SubSection> _extractSubSections(
    String rawHtml,
    String filePath,
    List<NavigationEntry> entries,
  ) {
    // 1. Tentar divisão por âncoras de sumário (#id) caso existam entradas apontando para IDs no arquivo
    final entriesWithAnchors = entries.where((e) => e.anchor != null && e.anchor!.isNotEmpty).toList();

    if (entriesWithAnchors.isNotEmpty) {
      final slices = _sliceByAnchors(rawHtml, filePath, entriesWithAnchors);
      if (slices.isNotEmpty) return slices;
    }

    // 2. Se houver entradas de sumário sem âncora, usar a primeira como título/nível principal
    if (entries.isNotEmpty) {
      final primary = entries.first;
      return [
        _SubSection(
          id: filePath,
          title: primary.title,
          htmlContent: rawHtml,
          level: primary.level,
        )
      ];
    }

    // 3. Fallback: Se o arquivo contiver múltiplos cabeçalhos h1/h2 ou tags <section>, dividir estruturalmente
    final headingSlices = _sliceByHeadings(rawHtml, filePath);
    if (headingSlices.length > 1) {
      return headingSlices;
    }

    // 4. Padrão: retorno de seção única com título derivado do cabeçalho HTML
    final title = HtmlSanitizer.extractTitle(rawHtml, fallbackTitle: 'Capítulo');
    return [
      _SubSection(
        id: filePath,
        title: title,
        htmlContent: rawHtml,
        level: 0,
      )
    ];
  }

  /// Fatia o HTML em sub-seções nos pontos onde os elementos com `id="anchor"` ou `name="anchor"` estão localizados.
  static List<_SubSection> _sliceByAnchors(
    String html,
    String filePath,
    List<NavigationEntry> anchorEntries,
  ) {
    final List<_AnchorMatch> matches = [];

    for (final entry in anchorEntries) {
      final anchor = entry.anchor!;
      final pattern = '(?:id|name)\\s*=\\s*["\']' + RegExp.escape(anchor) + '["\']';
      final reg = RegExp(pattern, caseSensitive: false);
      final match = reg.firstMatch(html);
      if (match != null) {
        matches.add(_AnchorMatch(
          entry: entry,
          position: match.start,
        ));
      }
    }

    if (matches.isEmpty) return [];

    matches.sort((a, b) => a.position.compareTo(b.position));

    final List<_SubSection> result = [];

    if (matches.first.position > 0) {
      final prologueHtml = html.substring(0, matches.first.position);
      final prologueClean = HtmlSanitizer.sanitize(prologueHtml);
      if (prologueClean.trim().length > 30) {
        result.add(_SubSection(
          id: '$filePath#prologue',
          title: HtmlSanitizer.extractTitle(prologueHtml, fallbackTitle: 'Abertura'),
          htmlContent: prologueHtml,
          level: matches.first.entry.level,
        ));
      }
    }

    for (int i = 0; i < matches.length; i++) {
      final current = matches[i];
      final int endPos = (i + 1 < matches.length) ? matches[i + 1].position : html.length;
      final sliceHtml = html.substring(current.position, endPos);

      result.add(_SubSection(
        id: '$filePath#${current.entry.anchor}',
        title: current.entry.title,
        htmlContent: sliceHtml,
        level: current.entry.level,
      ));
    }

    return result;
  }

  /// Fatia HTMLs por cabeçalhos `<h1>` ou `<h2>`.
  static List<_SubSection> _sliceByHeadings(String html, String filePath) {
    final headingReg = RegExp(
      r'<(?:h[12])\b[^>]*>(.*?)</(?:h[12])>',
      caseSensitive: false,
    );

    final matches = headingReg.allMatches(html).toList();
    if (matches.length <= 1) return [];

    final List<_SubSection> result = [];
    int cursor = 0;

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final int start = match.start;
      final int end = (i + 1 < matches.length) ? matches[i + 1].start : html.length;

      if (i == 0 && start > 0) {
        final introHtml = html.substring(cursor, start);
        if (HtmlSanitizer.sanitize(introHtml).trim().isNotEmpty) {
          result.add(_SubSection(
            id: '$filePath#section_0',
            title: HtmlSanitizer.extractTitle(introHtml, fallbackTitle: 'Introdução'),
            htmlContent: introHtml,
            level: 0,
          ));
        }
      }

      final sliceHtml = html.substring(start, end);
      final rawTitle = match.group(1) ?? '';
      final title = HtmlSanitizer.sanitize(rawTitle).trim();

      result.add(_SubSection(
        id: '$filePath#section_${i + 1}',
        title: title.isNotEmpty ? title : 'Seção ${i + 1}',
        htmlContent: sliceHtml,
        level: 0,
      ));

      cursor = end;
    }

    return result;
  }

  /// Extrai a lista completa de entradas de navegação (NAV/NCX) incluindo título, arquivo, âncora (#id) e nível.
  static List<NavigationEntry> _getNavigationEntries(
    String opfContent,
    String opfPath,
    Map<String, String> files,
  ) {
    final baseDir = opfPath.contains('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';
    final manifest = <String, String>{};

    for (final match in RegExp(r'<item\b([^>]*)>', caseSensitive: false).allMatches(opfContent)) {
      final attrs = match.group(1) ?? '';
      final id = _extractAttribute(attrs, 'id');
      final href = _extractAttribute(attrs, 'href');
      if (id != null && href != null) {
        manifest[id] = normalizeArchivePath('$baseDir${Uri.decodeFull(href)}');
      }
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

    final candidates = <String>[
      if (navPath != null) navPath,
      ...files.keys.where((path) => path.toLowerCase().endsWith('.ncx'))
    ];

    final entries = <NavigationEntry>[];

    for (final candidate in candidates) {
      final content = files[candidate];
      if (content == null) continue;
      final base = candidate.contains('/') ? candidate.substring(0, candidate.lastIndexOf('/') + 1) : '';

      if (candidate.endsWith('.ncx')) {
        _parseNcxContent(content, base, entries);
      } else {
        _parseNavHtmlContent(content, base, entries);
      }
    }

    return entries;
  }

  static void _parseNcxContent(String ncxXml, String base, List<NavigationEntry> target) {
    final navPointRegex = RegExp(r'<navPoint\b[^>]*>(.*?)</navPoint>', caseSensitive: false, dotAll: true);

    void processXmlFragment(String xml, int currentLevel) {
      final matches = navPointRegex.allMatches(xml);
      for (final match in matches) {
        final innerXml = match.group(1) ?? '';
        final labelMatch = RegExp(r'<text[^>]*>(.*?)</text>', caseSensitive: false).firstMatch(innerXml);
        final contentTagMatch = RegExp(r'<content\b([^>]*)>', caseSensitive: false).firstMatch(innerXml);

        final title = HtmlSanitizer.sanitize(labelMatch?.group(1) ?? '').trim();
        final rawSrc = contentTagMatch != null ? _extractAttribute(contentTagMatch.group(1) ?? '', 'src') : null;

        if (title.isNotEmpty && rawSrc != null) {
          final decoded = Uri.decodeFull(rawSrc);
          final parts = decoded.split('#');
          final hrefFile = parts.first;
          final anchor = parts.length > 1 ? parts.last : null;
          final normalizedPath = normalizeArchivePath('$base$hrefFile');

          target.add(NavigationEntry(
            title: title,
            path: normalizedPath,
            anchor: anchor,
            level: currentLevel,
          ));
        }

        final childXml = innerXml.replaceAll(RegExp(r'<navLabel>.*?</navLabel>', caseSensitive: false, dotAll: true), '');
        if (childXml.contains('<navPoint')) {
          processXmlFragment(childXml, currentLevel + 1);
        }
      }
    }

    processXmlFragment(ncxXml, 0);
  }

  static void _parseNavHtmlContent(String navHtml, String base, List<NavigationEntry> target) {
    final linkRegex = RegExp(r'<a\b([^>]*)>(.*?)</a>', caseSensitive: false, dotAll: true);

    for (final match in linkRegex.allMatches(navHtml)) {
      final attrs = match.group(1) ?? '';
      final rawHref = _extractAttribute(attrs, 'href');
      if (rawHref == null) continue;

      final title = HtmlSanitizer.sanitize(match.group(2) ?? '').trim();
      if (title.isEmpty) continue;

      final decoded = Uri.decodeFull(rawHref);
      final parts = decoded.split('#');
      final hrefFile = parts.first;
      final anchor = parts.length > 1 ? parts.last : null;
      final normalizedPath = normalizeArchivePath('$base$hrefFile');

      target.add(NavigationEntry(
        title: title,
        path: normalizedPath,
        anchor: anchor,
        level: 0,
      ));
    }
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
      '\\b' + RegExp.escape(name) + '\\s*=\\s*["\']([^"\']+)["\']',
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

  static Uint8List? _extractCoverImage(
    String opfContent,
    String opfPath,
    Map<String, Uint8List> resources,
  ) {
    if (resources.isEmpty) return null;

    final String opfDir = normalizeArchivePath(_extractPathDir(opfPath));
    String? coverHref;

    // 1. EPUB 3: <item ... properties="cover-image" ... href="..."/>
    final epub3Match = RegExp(
      r'<item\b[^>]*properties="[^"]*cover-image[^"]*"[^>]*href="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(opfContent) ??
    RegExp(
      r"<item\b[^>]*properties='[^']*cover-image[^']*'[^>]*href='([^']+)'",
      caseSensitive: false,
    ).firstMatch(opfContent);

    if (epub3Match != null) {
      coverHref = epub3Match.group(1);
    }

    // 2. EPUB 2: <meta name="cover" content="cover-id"/>
    if (coverHref == null) {
      final metaMatch = RegExp(
        r'<meta\b[^>]*name="cover"[^>]*content="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(opfContent) ??
      RegExp(
        r"<meta\b[^>]*name='cover'[^>]*content='([^']+)'",
        caseSensitive: false,
      ).firstMatch(opfContent);

      if (metaMatch != null) {
        final coverId = metaMatch.group(1)!;
        final itemMatch = RegExp(
          '<item\\b[^>]*id="${RegExp.escape(coverId)}"[^>]*href="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(opfContent) ??
        RegExp(
          "<item\\b[^>]*id='${RegExp.escape(coverId)}'[^>]*href='([^']+)'",
          caseSensitive: false,
        ).firstMatch(opfContent);

        if (itemMatch != null) {
          coverHref = itemMatch.group(1);
        }
      }
    }

    // 3. Fallback: item id containing "cover"
    if (coverHref == null) {
      final itemCoverMatch = RegExp(
        r'<item\b[^>]*id="(?:cover|cover-image|cover_image)"[^>]*href="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(opfContent) ??
      RegExp(
        r"<item\b[^>]*id='(?:cover|cover-image|cover_image)'[^>]*href='([^']+)'",
        caseSensitive: false,
      ).firstMatch(opfContent);

      if (itemCoverMatch != null) {
        coverHref = itemCoverMatch.group(1);
      }
    }

    if (coverHref != null) {
      final String decoded = Uri.decodeFull(coverHref);
      final String targetPath = normalizeArchivePath(
        opfDir.isEmpty ? decoded : '$opfDir/$decoded',
      );
      if (resources.containsKey(targetPath)) {
        return resources[targetPath];
      }
      for (final entry in resources.entries) {
        if (normalizeArchivePath(entry.key) == targetPath) {
          return entry.value;
        }
      }
    }

    // 4. Loose search for any image with "cover" or "capa" in path
    for (final entry in resources.entries) {
      final lower = entry.key.toLowerCase();
      if ((lower.contains('cover') || lower.contains('capa')) &&
          (lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif'))) {
        return entry.value;
      }
    }

    return null;
  }

  static String _extractPathDir(String path) {
    final idx = path.lastIndexOf('/');
    if (idx == -1) return '';
    return path.substring(0, idx);
  }
}

class _SubSection {
  final String id;
  final String title;
  final String htmlContent;
  final int level;

  _SubSection({
    required this.id,
    required this.title,
    required this.htmlContent,
    required this.level,
  });
}

class _AnchorMatch {
  final NavigationEntry entry;
  final int position;

  _AnchorMatch({
    required this.entry,
    required this.position,
  });
}
