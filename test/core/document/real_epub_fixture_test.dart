import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_bytes_importer.dart';

void main() {
  test('parses the checked-in real Portuguese EPUB fixture', () {
    final bytes = File('test/fixtures/valid_portuguese_sample.epub').readAsBytesSync();
    final book = const EpubBytesImporter().importBytes(
      name: 'valid_portuguese_sample.epub',
      bytes: Uint8List.fromList(bytes),
    );

    expect(book.title, 'O Livro de Teste — Síntese de Voz');
    expect(book.author, 'Equipe de Teste');
    expect(book.chapters, hasLength(2));
    expect(book.chapters.first.title, 'Capítulo um');
    expect(book.chapters.first.cleanText, contains('ação, órgão, avó e coração'));
    expect(book.chapters[1].title, 'Capítulo dois');
  });
}
