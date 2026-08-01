import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'epub_model.dart';
import 'saved_book.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

/// Persiste EPUBs e posição de leitura no diretório privado do aplicativo.
/// Funciona sem permissões amplas de armazenamento em Android e Windows.
class SavedBookRepository {
  final SupportDirectoryProvider _supportDirectoryProvider;

  SavedBookRepository({SupportDirectoryProvider? supportDirectoryProvider})
      : _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory;

  Future<Directory> _booksDirectory() async {
    final root = await _supportDirectoryProvider();
    final directory = Directory(p.join(root.path, 'saved_books'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<List<SavedBookRecord>> list() async {
    final directory = await _booksDirectory();
    final records = <SavedBookRecord>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString());
        if (json is Map<String, dynamic>) {
          final record = SavedBookRecord.fromJson(json);
          if (_isSafeId(record.id) &&
              await File(_epubPath(directory, record.id)).exists()) {
            records.add(record);
          }
        }
      } on Object {
        // Um registro corrompido não deve impedir a abertura da biblioteca.
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  Future<SavedBookData?> load(String id) async {
    if (!_isSafeId(id)) return null;
    final directory = await _booksDirectory();
    final metadataFile = File(_jsonPath(directory, id));
    final epubFile = File(_epubPath(directory, id));
    if (!await metadataFile.exists() || !await epubFile.exists()) return null;
    try {
      final json = jsonDecode(await metadataFile.readAsString());
      if (json is! Map<String, dynamic>) return null;
      return SavedBookData(
        record: SavedBookRecord.fromJson(json),
        bytes: await epubFile.readAsBytes(),
      );
    } on Object {
      return null;
    }
  }

  Future<SavedBookRecord> saveNew({
    required String fileName,
    required Uint8List bytes,
    required EpubBook book,
  }) async {
    final directory = await _booksDirectory();
    final contentHash = _fingerprint(bytes);
    final existing = (await list()).where(
      (record) => record.contentHash == contentHash,
    );
    if (existing.isNotEmpty) return existing.first;

    final id = 'book-$contentHash';
    final record = SavedBookRecord(
      id: id,
      fileName: fileName,
      title: book.title,
      author: book.author,
      contentHash: contentHash,
      totalChapters: book.totalChapters,
      chapterIndex: 0,
      sentenceIndex: 0,
      progress: 0,
      updatedAt: DateTime.now(),
    );
    await _write(directory, record, bytes);
    return record;
  }

  Future<void> update(SavedBookRecord record) async {
    if (!_isSafeId(record.id)) return;
    final directory = await _booksDirectory();
    final epubFile = File(_epubPath(directory, record.id));
    if (!await epubFile.exists()) return;
    final metadataFile = File(_jsonPath(directory, record.id));
    await metadataFile.writeAsString(jsonEncode(record.toJson()), flush: true);
  }

  Future<void> delete(String id) async {
    if (!_isSafeId(id)) return;
    final directory = await _booksDirectory();
    final files = [
      File(_epubPath(directory, id)),
      File(_jsonPath(directory, id))
    ];
    for (final file in files) {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _write(
    Directory directory,
    SavedBookRecord record,
    Uint8List bytes,
  ) async {
    final epubFile = File(_epubPath(directory, record.id));
    final metadataFile = File(_jsonPath(directory, record.id));
    await epubFile.writeAsBytes(bytes, flush: true);
    await metadataFile.writeAsString(jsonEncode(record.toJson()), flush: true);
  }

  String _epubPath(Directory directory, String id) =>
      p.join(directory.path, '$id.epub');
  String _jsonPath(Directory directory, String id) =>
      p.join(directory.path, '$id.json');

  bool _isSafeId(String id) => RegExp(r'^book-[a-f0-9]{8}$').hasMatch(id);

  String _fingerprint(Uint8List bytes) {
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
