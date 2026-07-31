import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'audio_player_service_interface.dart';
import 'wav_writer.dart';

/// Implementação do Serviço de Reprodução de Áudio baseada no pacote `audioplayers`.
/// Utiliza `BytesSource` para reprodução direta em memória compatível com Web, Windows, Android e iOS.
class AudioPlayerService implements IAudioPlayerService {
  final AudioPlayer _player;

  final StreamController<TTSAudioState> _stateController =
      StreamController<TTSAudioState>.broadcast();

  TTSAudioState _currentState = TTSAudioState.stopped;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  AudioPlayerService({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPositionChanged.listen((pos) {
      scheduleMicrotask(() {
        _currentPosition = pos;
      });
    });

    _player.onDurationChanged.listen((dur) {
      scheduleMicrotask(() {
        _currentDuration = dur;
      });
    });

    _player.onPlayerStateChanged.listen((state) {
      scheduleMicrotask(() {
        switch (state) {
          case PlayerState.playing:
            _updateState(TTSAudioState.playing);
            break;
          case PlayerState.paused:
            _updateState(TTSAudioState.paused);
            break;
          case PlayerState.stopped:
            _updateState(TTSAudioState.stopped);
            break;
          case PlayerState.completed:
            _updateState(TTSAudioState.completed);
            break;
          default:
            break;
        }
      });
    });
  }

  void _updateState(TTSAudioState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      scheduleMicrotask(() {
        if (!_stateController.isClosed) {
          _stateController.add(state);
        }
      });
    }
  }

  @override
  Future<void> loadAudioBuffer(AudioBuffer buffer) async {
    final Uint8List wavBytes = WavWriter.encodeToWav(buffer);
    await loadWavBytes(wavBytes);
  }

  @override
  Future<void> loadWavBytes(Uint8List bytes) async {
    await _player.stop();

    WavWriter.decodeWav(bytes);
    await _player.setSource(BytesSource(bytes));
    await _player.setPlaybackRate(_currentSpeed);
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> loadWavFile(String path) async {
    await _player.stop();
    await _player.setSource(DeviceFileSource(path));
    await _player.setPlaybackRate(_currentSpeed);
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> play() async {
    await _player.resume();
    _updateState(TTSAudioState.playing);
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updateState(TTSAudioState.paused);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentPosition = Duration.zero;
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _currentPosition = position;
  }

  @override
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _player.setPlaybackRate(speed);
  }

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  @override
  Stream<Duration?> get durationStream => _player.onDurationChanged;

  @override
  Stream<TTSAudioState> get stateStream => _stateController.stream;

  @override
  TTSAudioState get currentState => _currentState;

  @override
  double get currentSpeed => _currentSpeed;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get currentDuration => _currentDuration;

  @override
  void dispose() {
    _stateController.close();
    _player.dispose();
  }
}
