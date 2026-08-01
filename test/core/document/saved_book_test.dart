import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/document/saved_book.dart';
import 'package:tcc_tts_neural/core/document/saved_book_repository.dart';

void main() {
  test('SavedBookRecord preserva progresso e metadados no JSON', () {
    final original = SavedBookRecord(
      id: 'book-aabbccdd',
      fileName: 'dom-casmurro.epub',
      title: 'Dom Casmurro',
      author: 'Machado de Assis',
      contentHash: 'aabbccdd',
      totalChapters: 24,
      chapterIndex: 3,
      sentenceIndex: 37,
      progress: .42,
      updatedAt: DateTime.utc(2026, 8, 1),
    );

    final restored = SavedBookRecord.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.contentHash, 'aabbccdd');
    expect(restored.chapterIndex, 3);
    expect(restored.sentenceIndex, 37);
    expect(restored.completedSentenceIndex, -1);
    expect(restored.progressPercent, 42);
  });

  test('registro legado conserva checkpoint concluído conservador', () {
    final restored = SavedBookRecord.fromJson({
      'id': 'book-aabbccdd',
      'fileName': 'legacy.epub',
      'totalChapters': 1,
      'chapterIndex': 0,
      'sentenceIndex': 3,
      'progress': .5,
    });

    expect(restored.completedSentenceIndex, -1);
    expect(
        restored.copyWith(completedSentenceIndex: 2).completedSentenceIndex, 2);
  });

  test('copyWith limita progresso ao intervalo válido', () {
    final record = SavedBookRecord(
      id: 'book-aabbccdd',
      fileName: 'book.epub',
      title: 'Livro',
      author: 'Autor',
      totalChapters: 1,
      chapterIndex: 0,
      sentenceIndex: 0,
      progress: 0,
      updatedAt: DateTime.now(),
    );

    expect(record.copyWith(progress: 2).progressPercent, 100);
    expect(record.copyWith(progress: -.5).progress, 0);
  });

  group('SavedBookRepository', () {
    late Directory supportDirectory;
    late SavedBookRepository repository;

    Directory booksDirectory() => Directory(
          '${supportDirectory.path}${Platform.pathSeparator}saved_books',
        );

    setUp(() async {
      supportDirectory = await Directory.systemTemp.createTemp(
        'vozlume-saved-books-',
      );
      repository = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
      );
    });

    tearDown(() async {
      if (await supportDirectory.exists()) {
        await supportDirectory.delete(recursive: true);
      }
    });

    test('deduplica o mesmo EPUB e restaura bytes e progresso', () async {
      const book = EpubBook(
        title: 'Dom Casmurro',
        author: 'Machado de Assis',
        chapters: [
          EpubChapter(
            index: 0,
            id: 'capitulo-1',
            title: 'Capítulo 1',
            rawHtml: '<p>Olhos de ressaca.</p>',
            cleanText: 'Olhos de ressaca.',
          ),
        ],
      );
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final first = await repository.saveNew(
        fileName: 'dom-casmurro.epub',
        bytes: bytes,
        book: book,
      );
      final duplicate = await repository.saveNew(
        fileName: 'outra-copia.epub',
        bytes: bytes,
        book: book,
      );
      await repository.update(
        first.copyWith(chapterIndex: 0, sentenceIndex: 2, progress: .75),
      );

      final records = await repository.list();
      final loaded = await repository.load(first.id);
      expect(duplicate.id, first.id);
      expect(records, hasLength(1));
      expect(loaded, isNotNull);
      expect(loaded!.bytes, bytes);
      expect(loaded.record.sentenceIndex, 2);
      expect(loaded.record.progress, .75);
    });

    test('não confunde os fixtures que colidiam no FNV legado', () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final firstBytes = Uint8List.fromList(
        [0xB9, 0x06, 0xFB, 0x55, 0xA0, 0x21, 0x7D, 0x2B],
      );
      final secondBytes = Uint8List.fromList(
        [0xDC, 0x3A, 0x4C, 0xA7, 0x86, 0xB7, 0x3D, 0xE7],
      );

      final first = await repository.saveNew(
        fileName: 'first.epub',
        bytes: firstBytes,
        book: book,
      );
      final second = await repository.saveNew(
        fileName: 'second.epub',
        bytes: secondBytes,
        book: book,
      );

      expect(first.id, isNot(second.id));
      expect(first.contentHash, hasLength(64));
      expect((await repository.load(first.id))!.bytes, firstBytes);
      expect((await repository.load(second.id))!.bytes, secondBytes);
    });

    test('colisão de digest injetada cria sufixo sem alias de payload',
        () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final collidingRepository = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
        contentDigestProvider: (_) => 'a' * 64,
      );
      final first = await collidingRepository.saveNew(
        fileName: 'first.epub',
        bytes: Uint8List.fromList([1]),
        book: book,
      );
      final second = await collidingRepository.saveNew(
        fileName: 'second.epub',
        bytes: Uint8List.fromList([2]),
        book: book,
      );
      final duplicate = await collidingRepository.saveNew(
        fileName: 'copy.epub',
        bytes: Uint8List.fromList([1]),
        book: book,
      );

      expect(first.id, 'book-${'a' * 64}');
      expect(second.id, 'book-${'a' * 64}-1');
      expect(duplicate.id, first.id);
      expect((await collidingRepository.load(second.id))!.bytes, [2]);
    });

    test('novo repositório recarrega conteúdo persistido', () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final record = await repository.saveNew(
        fileName: 'restart.epub',
        bytes: Uint8List.fromList([7, 8]),
        book: book,
      );
      final restarted = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
      );

      expect((await restarted.load(record.id))!.bytes, [7, 8]);
    });

    test('recupera backup válido quando o JSON canônico está corrompido',
        () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final record = await repository.saveNew(
        fileName: 'recovery.epub',
        bytes: Uint8List.fromList([3, 4]),
        book: book,
      );
      final backupRecord = record.copyWith(sentenceIndex: 4, progress: .8);
      final canonical = File(
        '${booksDirectory().path}${Platform.pathSeparator}${record.id}.json',
      );
      final backup = File('${canonical.path}.bak');
      await backup.writeAsString(jsonEncode(backupRecord.toJson()),
          flush: true);
      await canonical.writeAsString('{malformed', flush: true);

      final restarted = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
      );
      final recovered = await restarted.load(record.id);

      expect(recovered!.record.sentenceIndex, 4);
      expect(recovered.record.progress, .8);
      expect(await backup.exists(), isFalse);
    });

    test('remove temp obsoleto sem substituir metadados canônicos válidos',
        () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final record = await repository.saveNew(
        fileName: 'temp.epub',
        bytes: Uint8List.fromList([5, 6]),
        book: book,
      );
      final temp = File(
        '${booksDirectory().path}${Platform.pathSeparator}${record.id}.json.tmp-999',
      );
      await temp.writeAsString(
        jsonEncode(record.copyWith(sentenceIndex: 9).toJson()),
        flush: true,
      );

      final restarted = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
      );
      final loaded = await restarted.load(record.id);

      expect(loaded!.record.sentenceIndex, record.sentenceIndex);
      expect(await temp.exists(), isFalse);
    });

    test('mantém registros legados de oito dígitos legíveis', () async {
      const legacyId = 'book-aabbccdd';
      await booksDirectory().create(recursive: true);
      await File(
              '${booksDirectory().path}${Platform.pathSeparator}$legacyId.epub')
          .writeAsBytes([1, 9], flush: true);
      await File(
              '${booksDirectory().path}${Platform.pathSeparator}$legacyId.json')
          .writeAsString(
        jsonEncode(
          SavedBookRecord(
            id: legacyId,
            fileName: 'legacy.epub',
            title: 'Legado',
            author: 'Autor',
            contentHash: 'aabbccdd',
            totalChapters: 1,
            chapterIndex: 0,
            sentenceIndex: 3,
            progress: .5,
            updatedAt: DateTime.utc(2026, 8, 1),
          ).toJson(),
        ),
        flush: true,
      );

      final loaded = await repository.load(legacyId);

      expect(loaded, isNotNull);
      expect(loaded!.bytes, [1, 9]);
      expect(loaded.record.sentenceIndex, 3);
    });

    test('limpa payload novo se a publicação de metadados falhar', () async {
      const book = EpubBook(title: 'Livro', author: 'Autor', chapters: []);
      final failingRepository = SavedBookRepository(
        supportDirectoryProvider: () async => supportDirectory,
        metadataTransactionWriter: (_, __) async {
          throw const FileSystemException('simulated metadata failure');
        },
      );

      await expectLater(
        failingRepository.saveNew(
          fileName: 'failure.epub',
          bytes: Uint8List.fromList([8]),
          book: book,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await booksDirectory().list().toList(), isEmpty);
    });

    test('remove payload e metadados e rejeita identificador inseguro',
        () async {
      const book = EpubBook(
        title: 'Livro',
        author: 'Autor',
        chapters: [],
      );
      final record = await repository.saveNew(
        fileName: 'livro.epub',
        bytes: Uint8List.fromList([9, 8, 7]),
        book: book,
      );

      expect(await repository.load('../outside'), isNull);
      await repository.delete('../outside');
      await repository.delete(record.id);

      expect(await repository.load(record.id), isNull);
      expect(await repository.list(), isEmpty);
    });
  });
}
