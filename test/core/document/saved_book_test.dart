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
    expect(restored.progressPercent, 42);
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
