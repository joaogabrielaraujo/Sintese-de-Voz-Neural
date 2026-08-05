import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/audio_player_service_interface.dart';
import 'package:tcc_tts_neural/core/audio/mock_audio_player_service.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';
import 'package:tcc_tts_neural/ui/app_theme.dart';
import 'package:tcc_tts_neural/ui/widgets/reader_page.dart';
import 'package:tcc_tts_neural/ui/widgets/responsive_navigation_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget themed(Widget child, {ThemeMode mode = ThemeMode.dark}) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: child,
    );
  }

  group('Accessibility, Focus & Shortcuts (14-08)', () {
    late MockAudioPlayerService player;

    setUp(() => player = MockAudioPlayerService());
    tearDown(() => player.dispose());

    testWidgets('Shortcuts trigger play/pause on Space and cancel/back on Escape', (tester) async {
      var playPauseCount = 0;
      var backCount = 0;

      const chapter = EpubChapter(
        index: 0,
        id: 'c1',
        title: 'Capítulo 1',
        rawHtml: '<p>Frase um. Frase dois.</p>',
        cleanText: 'Frase um. Frase dois.',
      );
      const book = EpubBook(
        title: 'Livro Acessível',
        author: 'Autor',
        chapters: [chapter],
      );

      await tester.pumpWidget(
        themed(
          ReaderPage(
            book: book,
            chapter: chapter,
            sentences: const [
              TextSentence(index: 0, text: 'Frase um.'),
              TextSentence(index: 1, text: 'Frase dois.'),
            ],
            activeIndex: 0,
            isProcessing: false,
            synthesisStatus: 'Pausada',
            playerService: player,
            audioState: TTSAudioState.stopped,
            currentPosition: Duration.zero,
            totalDuration: const Duration(seconds: 10),
            currentSpeed: 1.0,
            onBack: () => backCount++,
            onChapterChanged: (_) {},
            onSentenceSelected: (_) {},
            onCancelSelection: () {},
            onConfirmSelection: () {},
            onPlayPause: () => playPauseCount++,
            onStop: () {},
            onSeek: (_) {},
            onSpeedChanged: (_) {},
            onOpenMos: () {},
          ),
        ),
      );

      // Space triggers play/pause
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(playPauseCount, 1);

      // Escape triggers back when no selection is pending
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(backCount, 1);
    });

    testWidgets('Viewports 320px to 1440px render cleanly without overflow', (tester) async {
      final viewports = [
        const Size(320, 600),
        const Size(390, 844),
        const Size(800, 1280),
        const Size(899, 900),
        const Size(900, 900),
        const Size(1440, 900),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          themed(
            ResponsiveNavigationShell(
              destination: AppDestination.library,
              onDestinationChanged: (_) {},
              body: const Center(child: Text('Conteúdo Responsivo')),
            ),
          ),
        );

        expect(find.text('Conteúdo Responsivo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
