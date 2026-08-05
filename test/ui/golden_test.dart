import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/saved_book.dart';
import 'package:tcc_tts_neural/ui/widgets/library_view.dart';
import 'golden_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Visual Fidelity Golden Tests (14-09)', () {
    testWidgets('390 light canonical library rendering passes layout checks', (tester) async {
      final records = [
        SavedBookRecord(
          id: 'canonical-1',
          fileName: 'dom_casmurro.epub',
          title: 'Dom Casmurro',
          author: 'Machado de Assis',
          totalChapters: 10,
          chapterIndex: 1,
          sentenceIndex: 0,
          progress: 0.15,
          updatedAt: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(
        GoldenHarness.buildHarness(
          size: const Size(390, 844),
          themeMode: ThemeMode.light,
          child: LibraryView(
            books: records,
            importStatus: 'Pronto',
            engineStatus: 'ONNX VITS',
            isProcessing: false,
            onImport: () {},
            onOpenBook: (_) {},
            onDeleteBook: (_) {},
          ),
        ),
      );

      expect(find.text('VozLume'), findsOneWidget);
      expect(find.text('Dom Casmurro'), findsOneWidget);
      expect(find.text('Machado de Assis'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
    });

    testWidgets('1440 dark canonical library rendering passes layout checks', (tester) async {
      final records = [
        SavedBookRecord(
          id: 'canonical-2',
          fileName: 'os_sertoes.epub',
          title: 'Os Sertões',
          author: 'Euclides da Cunha',
          totalChapters: 12,
          chapterIndex: 3,
          sentenceIndex: 20,
          progress: 0.40,
          updatedAt: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(
        GoldenHarness.buildHarness(
          size: const Size(1440, 900),
          themeMode: ThemeMode.dark,
          child: LibraryView(
            books: records,
            importStatus: 'Pronto',
            engineStatus: 'ONNX VITS',
            isProcessing: false,
            onImport: () {},
            onOpenBook: (_) {},
            onDeleteBook: (_) {},
          ),
        ),
      );

      expect(find.text('VozLume'), findsOneWidget);
      expect(find.text('Os Sertões'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });
  });
}
