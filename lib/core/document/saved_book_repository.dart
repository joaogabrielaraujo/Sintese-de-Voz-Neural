import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'epub_model.dart';
import 'saved_book.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();
typedef ContentDigestProvider = String Function(Uint8List bytes);
typedef MetadataTransactionWriter = Future<void> Function(
  Directory directory,
  SavedBookRecord record,
);

/// Persiste EPUBs e posição de leitura no diretório privado do aplicativo.
/// Funciona sem permissões amplas de armazenamento em Android e Windows.
class SavedBookRepository {
  final SupportDirectoryProvider _supportDirectoryProvider;
  final ContentDigestProvider _contentDigestProvider;
  final MetadataTransactionWriter? _metadataTransactionWriter;
  int _transactionSequence = 0;

  SavedBookRepository({
    SupportDirectoryProvider? supportDirectoryProvider,
    ContentDigestProvider? contentDigestProvider,
    MetadataTransactionWriter? metadataTransactionWriter,
  })  : _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory,
        _contentDigestProvider = contentDigestProvider ?? _sha256,
        _metadataTransactionWriter = metadataTransactionWriter;

  Future<Directory> _booksDirectory() async {
    final root = await _supportDirectoryProvider();
    final directory = Directory(p.join(root.path, 'saved_books'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<List<SavedBookRecord>> list() async {
    final directory = await _booksDirectory();
    await _recoverTransactions(directory);
    final records = <SavedBookRecord>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString());
        if (json is Map<String, dynamic>) {
          final record = SavedBookRecord.fromJson(json);
          if (_isSafeId(record.id) &&
              entity.path == _jsonPath(directory, record.id) &&
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
    await _recoverTransactions(directory);
    final metadataFile = File(_jsonPath(directory, id));
    final epubFile = File(_epubPath(directory, id));
    if (!await metadataFile.exists() || !await epubFile.exists()) return null;
    try {
      final json = jsonDecode(await metadataFile.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final record = SavedBookRecord.fromJson(json);
      if (record.id != id) return null;
      return SavedBookData(
        record: record,
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
    final contentHash = _contentDigestProvider(bytes);
    final existing = (await list()).where(
      (record) => record.contentHash == contentHash,
    );
    for (final record in existing) {
      final payload = File(_epubPath(directory, record.id));
      if (await _payloadsEqual(payload, bytes)) return record;
    }

    final id = await _nextAvailableId(directory, contentHash);
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
    final epubFile = File(_epubPath(directory, record.id));
    try {
      await epubFile.writeAsBytes(bytes, flush: true);
      await _writeMetadataTransaction(directory, record);
    } on Object {
      if (await epubFile.exists()) await epubFile.delete();
      await _removeTransactionArtifacts(directory, record.id);
      rethrow;
    }
    return record;
  }

  Future<void> update(SavedBookRecord record) async {
    if (!_isSafeId(record.id)) return;
    final directory = await _booksDirectory();
    final epubFile = File(_epubPath(directory, record.id));
    if (!await epubFile.exists()) return;
    await _writeMetadataTransaction(directory, record);
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

  Future<bool> _payloadsEqual(File payload, Uint8List bytes) async {
    if (!await payload.exists() || await payload.length() != bytes.length) {
      return false;
    }
    final existing = await payload.readAsBytes();
    if (existing.length != bytes.length) return false;
    for (var index = 0; index < bytes.length; index++) {
      if (existing[index] != bytes[index]) return false;
    }
    return true;
  }

  Future<String> _nextAvailableId(Directory directory, String digest) async {
    for (var suffix = 0;; suffix++) {
      final id = suffix == 0 ? 'book-$digest' : 'book-$digest-$suffix';
      final hasMetadata = await File(_jsonPath(directory, id)).exists();
      final hasPayload = await File(_epubPath(directory, id)).exists();
      if (!hasMetadata && !hasPayload) return id;
    }
  }

  Future<void> _writeMetadataTransaction(
    Directory directory,
    SavedBookRecord record,
  ) async {
    if (_metadataTransactionWriter != null) {
      return _metadataTransactionWriter!(directory, record);
    }
    final metadataFile = File(_jsonPath(directory, record.id));
    final backupFile = File(_backupPath(directory, record.id));
    final tempFile = File(_tempPath(directory, record.id));
    await tempFile.writeAsString(jsonEncode(record.toJson()), flush: true);
    final validated = await _readRecord(tempFile, record.id);
    if (validated == null) {
      await tempFile.delete();
      throw FileSystemException('Invalid metadata transaction', tempFile.path);
    }

    var movedCanonical = false;
    try {
      if (await metadataFile.exists()) {
        if (await backupFile.exists()) await backupFile.delete();
        await metadataFile.rename(backupFile.path);
        movedCanonical = true;
      }
      await tempFile.rename(metadataFile.path);
      if (await backupFile.exists()) await backupFile.delete();
    } on Object {
      if (await tempFile.exists()) await tempFile.delete();
      if (movedCanonical &&
          !await metadataFile.exists() &&
          await backupFile.exists()) {
        await backupFile.rename(metadataFile.path);
      }
      rethrow;
    }
  }

  Future<void> _recoverTransactions(Directory directory) async {
    final backups = <String, File>{};
    final temps = <File>[];
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      final backupMatch = RegExp(
              r'^(book-(?:[a-f0-9]{8}|[a-f0-9]{64}(?:-[1-9][0-9]*)?))\.json\.bak$')
          .firstMatch(name);
      if (backupMatch != null) {
        backups[backupMatch.group(1)!] = entity;
      } else if (RegExp(
              r'^book-(?:[a-f0-9]{8}|[a-f0-9]{64}(?:-[1-9][0-9]*)?)\.json\.tmp-[0-9]+$')
          .hasMatch(name)) {
        temps.add(entity);
      }
    }

    for (final entry in backups.entries) {
      final id = entry.key;
      final metadataFile = File(_jsonPath(directory, id));
      final payloadFile = File(_epubPath(directory, id));
      final canonical = await _readRecord(metadataFile, id);
      final backup = await _readRecord(entry.value, id);
      if (canonical == null && backup != null && await payloadFile.exists()) {
        if (await metadataFile.exists()) await metadataFile.delete();
        await entry.value.rename(metadataFile.path);
      } else if (canonical != null && await payloadFile.exists()) {
        await entry.value.delete();
      }
    }

    for (final temp in temps) {
      final id = RegExp(
              r'^(book-(?:[a-f0-9]{8}|[a-f0-9]{64}(?:-[1-9][0-9]*)?))\.json\.tmp-[0-9]+$')
          .firstMatch(p.basename(temp.path))!
          .group(1)!;
      if (await _readRecord(File(_jsonPath(directory, id)), id) != null &&
          await File(_epubPath(directory, id)).exists()) {
        await temp.delete();
      }
    }
  }

  Future<void> _removeTransactionArtifacts(
      Directory directory, String id) async {
    final backup = File(_backupPath(directory, id));
    if (await backup.exists()) await backup.delete();
    await for (final entity in directory.list()) {
      if (entity is File &&
          p.basename(entity.path).startsWith('$id.json.tmp-')) {
        await entity.delete();
      }
    }
  }

  Future<SavedBookRecord?> _readRecord(File file, String expectedId) async {
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final record = SavedBookRecord.fromJson(json);
      return record.id == expectedId && _isSafeId(record.id) ? record : null;
    } on Object {
      return null;
    }
  }

  String _epubPath(Directory directory, String id) =>
      p.join(directory.path, '$id.epub');
  String _jsonPath(Directory directory, String id) =>
      p.join(directory.path, '$id.json');
  String _backupPath(Directory directory, String id) =>
      p.join(directory.path, '$id.json.bak');
  String _tempPath(Directory directory, String id) =>
      p.join(directory.path, '$id.json.tmp-${++_transactionSequence}');

  bool _isSafeId(String id) => RegExp(
        r'^book-(?:[a-f0-9]{8}|[a-f0-9]{64}(?:-[1-9][0-9]*)?)$',
      ).hasMatch(id);

  static String _sha256(Uint8List bytes) => sha256.convert(bytes).toString();
}
