import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/audio_player_service_interface.dart';
import 'package:tcc_tts_neural/core/audio/mock_audio_player_service.dart';

void main() {
  group('MockAudioPlayerService Tests', () {
    late MockAudioPlayerService playerService;

    setUp(() {
      playerService = MockAudioPlayerService();
    });

    tearDown(() {
      playerService.dispose();
    });

    test('Estado inicial deve ser stopped', () {
      expect(playerService.currentState, equals(TTSAudioState.stopped));
      expect(playerService.currentPosition, equals(Duration.zero));
    });

    test('loadWavBytes deve atualizar duracao estimada e emitir no stream', () async {
      // 88200 bytes = ~2 segundos de audio PCM
      final dummyWav = Uint8List(88200);

      expect(
        playerService.durationStream,
        emits(predicate<Duration?>((d) => d != null && d.inSeconds == 2)),
      );

      await playerService.loadWavBytes(dummyWav);
      expect(playerService.currentDuration.inSeconds, equals(2));
    });

    test('Transição de estados play, pause, stop', () async {
      await playerService.loadWavFile('dummy.wav');

      final states = <TTSAudioState>[];
      playerService.stateStream.listen(states.add);

      await playerService.play();
      expect(playerService.currentState, equals(TTSAudioState.playing));

      await playerService.pause();
      expect(playerService.currentState, equals(TTSAudioState.paused));

      await playerService.stop();
      expect(playerService.currentState, equals(TTSAudioState.stopped));
      expect(playerService.currentPosition, equals(Duration.zero));

      expect(states, containsAllInOrder([
        TTSAudioState.playing,
        TTSAudioState.paused,
        TTSAudioState.stopped,
      ]));
    });

    test('Alteração de velocidade de reprodução (speed)', () async {
      await playerService.setSpeed(1.5);
      expect(playerService.currentSpeed, equals(1.5));
    });

    test('Seek deve alterar a posição corrente', () async {
      await playerService.loadWavFile('dummy.wav');
      await playerService.seek(const Duration(seconds: 5));
      expect(playerService.currentPosition, equals(const Duration(seconds: 5)));
    });
  });
}
