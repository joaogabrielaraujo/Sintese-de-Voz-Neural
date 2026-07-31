import 'dart:typed_data';
import 'wav_writer.dart';

/// Estados possíveis do player de áudio para síntese neural.
enum TTSAudioState {
  stopped,
  playing,
  paused,
  completed,
}

/// Interface para o Serviço de Reprodução de Áudio da Síntese Neural.
abstract class IAudioPlayerService {
  /// Carrega e encoda um [AudioBuffer] garantindo o cabeçalho RIFF/WAV de 44 bytes.
  Future<void> loadAudioBuffer(AudioBuffer buffer);

  /// Carrega bytes de áudio no formato WAV (ex: gerados pelo PipelineOrchestrator).
  Future<void> loadWavBytes(Uint8List bytes);

  /// Carrega áudio a partir de um caminho no sistema de arquivos.
  Future<void> loadWavFile(String path);

  /// Inicia ou retoma a reprodução do áudio.
  Future<void> play();

  /// Pausa a reprodução mantendo a posição atual.
  Future<void> pause();

  /// Para a reprodução e reinicia a posição para zero.
  Future<void> stop();

  /// Salta para uma posição específica no áudio.
  Future<void> seek(Duration position);

  /// Define a velocidade da síntese/reprodução (ex: 0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  Future<void> setSpeed(double speed);

  /// Stream do progresso da posição de reprodução.
  Stream<Duration> get positionStream;

  /// Stream da duração total do áudio.
  Stream<Duration?> get durationStream;

  /// Stream dos estados de reprodução.
  Stream<TTSAudioState> get stateStream;

  /// Obtém o estado atual da reprodução.
  TTSAudioState get currentState;

  /// Obtém a velocidade atual.
  double get currentSpeed;

  /// Obtém a posição atual.
  Duration get currentPosition;

  /// Obtém a duração total do áudio.
  Duration get currentDuration;

  /// Libera recursos do player.
  void dispose();
}
