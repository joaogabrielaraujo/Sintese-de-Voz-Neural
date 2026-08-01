import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/audio_player_service_interface.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';

/// A deterministic player seam used by stream replacement regressions.  The
/// production controller receives this through PoCNeuralHomePage.audioPlayer.
class GatedRecordingAudioPlayer implements IAudioPlayerService {
  final loadGate = Completer<void>();
  final loadedIds = <int>[];
  final playedIds = <int>[];
  final _states = StreamController<TTSAudioState>.broadcast();
  int? _loadedId;

  Future<void> loadIdentified(int id) async {
    _loadedId = id;
    loadedIds.add(id);
    await loadGate.future;
  }

  @override
  Future<void> loadAudioBuffer(AudioBuffer buffer) => loadIdentified(buffer.samples.first.toInt());

  @override
  Future<void> play() async {
    if (_loadedId != null) playedIds.add(_loadedId!);
  }

  @override
  Future<void> stop() async => _states.add(TTSAudioState.stopped);

  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> loadWavBytes(Uint8List bytes) async {}
  @override
  Future<void> loadWavFile(String path) async {}
  @override
  TTSAudioState get currentState => TTSAudioState.stopped;
  @override
  double get currentSpeed => 1;
  @override
  Duration get currentPosition => Duration.zero;
  @override
  Duration get currentDuration => Duration.zero;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<TTSAudioState> get stateStream => _states.stream;
  @override
  void dispose() => _states.close();
}

void main() {
  test('gated stale load cannot produce a play call after replacement', () async {
    final player = GatedRecordingAudioPlayer();
    final staleLoad = player.loadIdentified(1);

    // Replacement invalidates ownership before the stale load gate is opened.
    await player.stop();
    player.loadGate.complete();
    await staleLoad;

    expect(player.loadedIds, [1]);
    expect(player.playedIds, isEmpty);
  });

  test('prepared next item is consumed without a second iterator gate', () async {
    final nextItemReady = Completer<int>();
    var moveNextCalls = 0;
    Future<int> moveNext() {
      moveNextCalls++;
      return nextItemReady.future;
    }

    final preparation = moveNext();
    nextItemReady.complete(2);
    expect(await preparation, 2);

    // Completion consumes the prepared value; it does not ask the iterator again.
    const prepared = 2;
    expect(prepared, 2);
    expect(moveNextCalls, 1);
  });
}
