import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_bytes_importer.dart';

Uint8List _epubBytes({bool encodedChapterName = false}) {
  final chapterName = encodedChapterName ? 'capítulo 1.xhtml' : 'capitulo.xhtml';
  final href = encodedChapterName ? 'cap%C3%ADtulo%201.xhtml' : chapterName;
  final archive = Archive()
    ..addFile(ArchiveFile.string(
      'META-INF/container.xml',
      '<container><rootfiles><rootfile full-path="OPS/package.opf"/></rootfiles></container>',
    ))
    ..addFile(ArchiveFile.string(
      'OPS/package.opf',
      '''<package><metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:title>Livro de Teste</dc:title><dc:creator>Autora</dc:creator><dc:language>pt-BR</dc:language>
      </metadata><manifest><item id="c1" href="$href"/></manifest>
      <spine><itemref idref="c1"/></spine></package>''',
    ))
    ..addFile(ArchiveFile.string(
      'OPS/$chapterName',
      '<html><body><h1>Capítulo um</h1><p>Ação, órgão e avó.</p></body></html>',
    ));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  const importer = EpubBytesImporter();

  test('imports a real EPUB ZIP and preserves metadata, order, and UTF-8', () {
    final book = importer.importBytes(name: 'livro.epub', bytes: _epubBytes());

    expect(book.title, 'Livro de Teste');
    expect(book.author, 'Autora');
    expect(book.language, 'pt-BR');
    expect(book.chapters.single.cleanText, contains('Ação, órgão e avó.'));
  });

  test('resolves URL-encoded chapter hrefs relative to a nested OPF', () {
    final book = importer.importBytes(
      name: 'livro.epub',
      bytes: _epubBytes(encodedChapterName: true),
    );

    expect(book.chapters.single.title, 'Capítulo um');
  });

  test('rejects non-EPUB files before decoding', () {
    expect(
      () => importer.importBytes(name: 'livro.txt', bytes: Uint8List(0)),
      throwsA(isA<EpubImportException>()),
    );
  });

  test('rejects malformed ZIP bytes', () {
    expect(
      () => importer.importBytes(
        name: 'livro.epub',
        bytes: Uint8List.fromList(utf8.encode('not a zip')),
      ),
      throwsA(isA<EpubImportException>()),
    );
  });
}
