import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'epub_model.dart';
import 'epub_parser.dart';
import 'selected_document.dart';

class EpubImportException implements Exception {
  final String message;
  const EpubImportException(this.message);

  @override
  String toString() => message;
}

class EpubBytesImporter {
  const EpubBytesImporter();

  EpubBook importDocument(SelectedDocument document) {
    if (document.extension != 'epub') {
      throw const EpubImportException('Selecione um arquivo com extensão .epub.');
    }

    try {
      final archive = ZipDecoder().decodeBytes(document.bytes);
      final files = <String, String>{};
      for (final entry in archive) {
        if (entry.isFile) {
          final path = EpubParser.normalizeArchivePath(entry.name);
          files[path] = utf8.decode(entry.content as List<int>, allowMalformed: false);
        }
      }
      if (!files.containsKey('META-INF/container.xml')) {
        throw const EpubImportException('EPUB inválido: META-INF/container.xml não encontrado.');
      }
      final book = EpubParser.parseArchive(files);
      if (book.chapters.isEmpty) {
        throw const EpubImportException('EPUB inválido: nenhum capítulo legível foi encontrado.');
      }
      return book;
    } on EpubImportException {
      rethrow;
    } catch (_) {
      throw const EpubImportException('Não foi possível ler o arquivo EPUB.');
    }
  }

  EpubBook importBytes({required String name, required Uint8List bytes}) =>
      importDocument(SelectedDocument(name: name, bytes: bytes));
}
