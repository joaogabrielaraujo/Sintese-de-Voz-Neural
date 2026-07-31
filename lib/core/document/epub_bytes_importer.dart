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
  static const int maxImportBytes = 512 * 1024 * 1024;
  const EpubBytesImporter();

  EpubBook importDocument(SelectedDocument document) {
    if (document.extension != 'epub') {
      throw const EpubImportException('Selecione um arquivo com extensão .epub.');
    }

    if (document.bytes.length < 22) {
      throw const EpubImportException('EPUB inválido: arquivo muito pequeno.');
    }
    if (document.bytes.length > maxImportBytes) {
      throw const EpubImportException('EPUB excede o limite de 512 MB.');
    }
    final bytes = document.bytes;
    final hasZipSignature = bytes[0] == 0x50 && bytes[1] == 0x4B &&
        ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
            (bytes[2] == 0x05 && bytes[3] == 0x06) ||
            (bytes[2] == 0x07 && bytes[3] == 0x08));
    if (!hasZipSignature) {
      throw const EpubImportException('EPUB inválido: o arquivo não é um ZIP.');
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final files = <String, String>{};
      for (final entry in archive) {
        if (entry.isFile) {
          final path = EpubParser.normalizeArchivePath(entry.name);
          if (_isTextEntry(path)) {
            files[path] = utf8.decode(
              entry.content as List<int>,
              allowMalformed: false,
            );
          }
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

  static bool _isTextEntry(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath == 'mimetype' ||
        lowerPath.endsWith('.xml') ||
        lowerPath.endsWith('.opf') ||
        lowerPath.endsWith('.xhtml') ||
        lowerPath.endsWith('.html') ||
        lowerPath.endsWith('.htm') ||
        lowerPath.endsWith('.ncx') ||
        lowerPath.endsWith('.css');
  }
}
