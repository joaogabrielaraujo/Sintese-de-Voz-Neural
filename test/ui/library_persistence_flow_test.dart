import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/document/saved_book.dart';
import 'package:tcc_tts_neural/core/document/saved_book_repository.dart';
import 'package:tcc_tts_neural/ui/widgets/library_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Library Persistence & UI Flow', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('library_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('import complete restart resume flow', () async {
      final repo = SavedBookRepository(
        supportDirectoryProvider: () async => tempDir,
      );

      // Verify empty list initially
      var books = await repo.list();
      expect(books, isEmpty);

      // Save a new book using saveNew with EpubBook
      final dummyBook = EpubBook(
        title: 'Editorial Test Book',
        author: 'Author Name',
        chapters: [
          const EpubChapter(
            index: 0,
            id: 'ch1',
            title: 'Capítulo 1',
            rawHtml: '<p>Teste</p>',
            cleanText: 'Teste',
          ),
        ],
      );

      final record = await repo.saveNew(
        fileName: 'test_book.epub',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        book: dummyBook,
      );

      expect(record.title, 'Editorial Test Book');
      expect(record.progress, 0.0);

      // Update progress
      final updated = record.copyWith(
        chapterIndex: 0,
        sentenceIndex: 10,
        progress: 0.5,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated);

      // Restart (new repo instance on same storage directory)
      final repo2 = SavedBookRepository(
        supportDirectoryProvider: () async => tempDir,
      );
      books = await repo2.list();
      expect(books.length, 1);
      expect(books.first.chapterIndex, 0);
      expect(books.first.sentenceIndex, 10);
      expect(books.first.progress, 0.5);
      expect(books.first.progressPercent, 50);

      // Load payload bytes
      final loaded = await repo2.load(books.first.id);
      expect(loaded, isNotNull);
      expect(loaded!.bytes, [1, 2, 3, 4]);

      // Delete book
      await repo2.delete(books.first.id);
      books = await repo2.list();
      expect(books, isEmpty);
    });

    testWidgets('LibraryView renders empty, populated, and single-flight import card', (tester) async {
      final records = <SavedBookRecord>[
        SavedBookRecord(
          id: 'b1',
          fileName: 'book1.epub',
          title: 'Livro Editorial Longo para Teste de Duas Linhas no Card da Biblioteca',
          author: 'Autor Teste',
          totalChapters: 10,
          chapterIndex: 0,
          sentenceIndex: 5,
          progress: 0.25,
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryView(
              books: records,
              importStatus: 'Pronto para leitura',
              engineStatus: 'ONNX VITS',
              isProcessing: false,
              onImport: () {},
              onOpenBook: (_) {},
              onDeleteBook: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('VozLume'), findsOneWidget);
      expect(find.text('Importar EPUB'), findsOneWidget);
      expect(find.text('O arquivo permanece somente neste dispositivo.'), findsOneWidget);
      expect(find.byKey(const Key('saved-book-b1')), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });
  });
}
