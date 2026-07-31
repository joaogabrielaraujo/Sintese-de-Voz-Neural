import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/audio_player_service_interface.dart';
import 'package:tcc_tts_neural/core/audio/mock_audio_player_service.dart';
import 'package:tcc_tts_neural/core/metrics/mos_rating_model.dart';
import 'package:tcc_tts_neural/ui/widgets/audio_player_control_bar.dart';
import 'package:tcc_tts_neural/ui/widgets/mos_evaluation_dialog.dart';
import 'package:tcc_tts_neural/ui/widgets/sentence_highlight_view.dart';

void main() {
  group('Audio Player Widget Tests (Fase 6)', () {
    late MockAudioPlayerService mockPlayer;

    setUp(() {
      mockPlayer = MockAudioPlayerService();
    });

    tearDown(() {
      mockPlayer.dispose();
    });

    testWidgets('AudioPlayerControlBar exibe botões e sliders corretamente', (WidgetTester tester) async {
      bool playPauseCalled = false;
      bool stopCalled = false;
      bool mosDialogCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioPlayerControlBar(
              playerService: mockPlayer,
              currentState: TTSAudioState.stopped,
              currentPosition: Duration.zero,
              totalDuration: const Duration(seconds: 30),
              currentSpeed: 1.0,
              onPlayPausePressed: () => playPauseCalled = true,
              onStopPressed: () => stopCalled = true,
              onSeekChanged: (_) {},
              onSpeedChanged: (_) {},
              onOpenMOSDialog: () => mosDialogCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('Avaliar MOS'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(playPauseCalled, isTrue);

      await tester.tap(find.byIcon(Icons.stop));
      expect(stopCalled, isTrue);

      await tester.tap(find.text('Avaliar MOS'));
      expect(mosDialogCalled, isTrue);
    });

    testWidgets('SentenceHighlightView destaca sentença ativa', (WidgetTester tester) async {
      final sentences = [
        'Primeira sentença em áudio.',
        'Segunda sentença normalizada.',
        'Terceira sentença de teste.',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceHighlightView(
              sentences: sentences,
              activeIndex: 1,
            ),
          ),
        ),
      );

      expect(find.text('Primeira sentença em áudio.'), findsOneWidget);
      expect(find.text('Segunda sentença normalizada.'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget); // Ícone na sentença ativa (#2)
    });

    testWidgets('MOSEvaluationDialog permite salvar notas do MOS', (WidgetTester tester) async {
      MOSRating? savedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MOSEvaluationDialog(
                      sampleText: 'Texto de teste para avaliação MOS',
                      onSubmitted: (rating) => savedRating = rating,
                    ),
                  );
                },
                child: const Text('Abrir MOS'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir MOS'));
      await tester.pumpAndSettle();

      expect(find.text('Avaliação Auditiva (MOS)'), findsOneWidget);
      expect(find.text('Salvar Avaliação'), findsOneWidget);

      await tester.tap(find.text('Salvar Avaliação'));
      await tester.pumpAndSettle();

      expect(savedRating, isNotNull);
      expect(savedRating!.averageScore, equals(5.0)); // Padrão 5 estrelas
    });
  });
}
