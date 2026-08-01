import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/audio_player_service_interface.dart';
import 'package:tcc_tts_neural/core/audio/mock_audio_player_service.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/document/saved_book.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';
import 'package:tcc_tts_neural/ui/app_theme.dart';
import 'package:tcc_tts_neural/ui/widgets/library_view.dart';
import 'package:tcc_tts_neural/ui/widgets/reader_page.dart';
import 'package:tcc_tts_neural/ui/widgets/responsive_navigation_shell.dart';

void main() {
  Widget themed(Widget child) =>
      MaterialApp(theme: AppTheme.dark(), home: child);

  group('ResponsiveNavigationShell', () {
    testWidgets('usa barra inferior em largura Android compacta',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        themed(
          ResponsiveNavigationShell(
            destination: AppDestination.library,
            onDestinationChanged: (_) {},
            body: const SizedBox(),
          ),
        ),
      );

      expect(
          find.byKey(const Key('compact-bottom-navigation')), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('usa navegação lateral em janela Windows larga',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        themed(
          ResponsiveNavigationShell(
            destination: AppDestination.search,
            onDestinationChanged: (_) {},
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byKey(const Key('wide-navigation-rail')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('LibraryView', () {
    testWidgets('expõe estado vazio, offline e callback de importação',
        (tester) async {
      var imported = false;
      await tester.pumpWidget(
        themed(
          Scaffold(
            body: LibraryView(
              books: const [],
              importStatus: 'Nenhum EPUB carregado',
              engineStatus: 'Automático',
              isProcessing: false,
              onImport: () => imported = true,
              onOpenBook: (_) {},
              onDeleteBook: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.byKey(const Key('empty-library-state')), findsOneWidget);
      await tester.tap(find.byKey(const Key('import-epub-card')));
      expect(imported, isTrue);
    });

    testWidgets('filtra livros e preserva callback de abertura',
        (tester) async {
      final books = [
        SavedBookRecord(
          id: 'book-aabbccdd',
          fileName: 'dom.epub',
          title: 'Dom Casmurro',
          author: 'Machado de Assis',
          totalChapters: 10,
          chapterIndex: 2,
          sentenceIndex: 4,
          progress: .3,
          updatedAt: DateTime(2026),
        ),
        SavedBookRecord(
          id: 'book-11223344',
          fileName: 'sertoes.epub',
          title: 'Os Sertões',
          author: 'Euclides da Cunha',
          totalChapters: 8,
          chapterIndex: 0,
          sentenceIndex: 0,
          progress: .1,
          updatedAt: DateTime(2026),
        ),
      ];
      SavedBookRecord? opened;

      await tester.pumpWidget(
        themed(
          Scaffold(
            body: LibraryView(
              books: books,
              importStatus: '',
              engineStatus: 'Automático',
              isProcessing: false,
              searchMode: true,
              searchQuery: 'machado',
              onImport: () {},
              onOpenBook: (book) => opened = book,
              onDeleteBook: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Dom Casmurro'), findsOneWidget);
      expect(find.text('Os Sertões'), findsNothing);
      await tester.tap(find.byKey(const Key('saved-book-book-aabbccdd')));
      expect(opened?.title, 'Dom Casmurro');
    });
  });

  group('ReaderPage', () {
    late MockAudioPlayerService player;

    setUp(() => player = MockAudioPlayerService());
    tearDown(() => player.dispose());

    ReaderPage reader({required ValueChanged<int> onSelected}) {
      const chapter = EpubChapter(
        index: 0,
        id: 'c1',
        title: 'Capítulo 1',
        rawHtml: '<p>Primeira. Segunda.</p>',
        cleanText: 'Primeira. Segunda.',
      );
      const book = EpubBook(
        title: 'Livro de teste',
        author: 'Autora',
        chapters: [chapter],
      );
      return ReaderPage(
        book: book,
        chapter: chapter,
        sentences: const [
          TextSentence(index: 0, text: 'Primeira.', isParagraphEnd: false),
          TextSentence(index: 1, text: 'Segunda.', isParagraphEnd: true),
        ],
        activeIndex: 0,
        pendingIndex: 1,
        isProcessing: false,
        synthesisStatus: 'Pausada',
        playerService: player,
        audioState: TTSAudioState.paused,
        currentPosition: Duration.zero,
        totalDuration: const Duration(seconds: 5),
        currentSpeed: 1,
        onBack: () {},
        onChapterChanged: (_) {},
        onSentenceSelected: onSelected,
        onCancelSelection: () {},
        onConfirmSelection: () {},
        onPlayPause: () {},
        onStop: () {},
        onSeek: (_) {},
        onSpeedChanged: (_) {},
        onOpenMos: () {},
      );
    }

    testWidgets('limita texto e ancora player ao lado em largura Windows',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(themed(reader(onSelected: (_) {})));

      expect(find.byKey(const Key('wide-reader-layout')), findsOneWidget);
      expect(find.byKey(const Key('audio-player-control-bar')), findsOneWidget);
      expect(
        find.byKey(const Key('reader-selection-confirmation')),
        findsOneWidget,
      );
    });

    testWidgets('setas usam o mesmo callback de seleção do toque',
        (tester) async {
      int? selected;
      await tester.pumpWidget(
        themed(reader(onSelected: (value) => selected = value)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(selected, 0);
    });
  });
}
