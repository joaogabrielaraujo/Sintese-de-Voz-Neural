import 'dart:async';
import 'dart:typed_data';
import 'audio_player_service_interface.dart';

import 'wav_writer.dart';

/// Implementação Mock do Serviço de Áudio para uso em Testes de Unidade e UI.
class MockAudioPlayerService implements IAudioPlayerService {
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<TTSAudioState> _stateController =
      StreamController<TTSAudioState>.broadcast();

  TTSAudioState _currentState = TTSAudioState.stopped;
  double _currentSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = const Duration(seconds: 10);
  Timer? _mockTimer;

  @override
  Future<void> loadAudioBuffer(AudioBuffer buffer) async {
    final bytes = WavWriter.encodeToWav(buffer);
    await loadWavBytes(bytes);
  }

  @override
  Future<void> loadWavBytes(Uint8List bytes) async {
    _currentPosition = Duration.zero;
    // Estima a duração baseada no tamanho dos bytes (assumindo PCM 16-bit 22.050Hz mono ~= 44100 bytes/s)
    final estimatedSecs = (bytes.length / 44100).clamp(1.0, 300.0);
    _currentDuration = Duration(milliseconds: (estimatedSecs * 1000).toInt());
    _durationController.add(_currentDuration);
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> loadWavFile(String path) async {
    _currentPosition = Duration.zero;
    _currentDuration = const Duration(seconds: 10);
    _durationController.add(_currentDuration);
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> play() async {
    _updateState(TTSAudioState.playing);
    _startMockPlaybackTimer();
  }

  @override
  Future<void> pause() async {
    _mockTimer?.cancel();
    _updateState(TTSAudioState.paused);
  }

  @override
  Future<void> stop() async {
    _mockTimer?.cancel();
    _currentPosition = Duration.zero;
    _positionController.add(_currentPosition);
    _updateState(TTSAudioState.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    _positionController.add(_currentPosition);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
  }

  void _startMockPlaybackTimer() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_currentState != TTSAudioState.playing) {
        timer.cancel();
        return;
      }
      final nextMs = _currentPosition.inMilliseconds + (200 * _currentSpeed).toInt();
      if (nextMs >= _currentDuration.inMilliseconds) {
        _currentPosition = _currentDuration;
        _positionController.add(_currentPosition);
        _updateState(TTSAudioState.completed);
        timer.cancel();
      } else {
        _currentPosition = Duration(milliseconds: nextMs);
        _positionController.add(_currentPosition);
      }
    });
  }

  void _updateState(TTSAudioState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

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
    _mockTimer?.cancel();
    _positionController.close();
    _durationController.close();
    _stateController.close();
  }
}
