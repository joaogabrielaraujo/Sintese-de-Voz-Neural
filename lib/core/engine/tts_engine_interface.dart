import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import '../metrics/rtf_calculator.dart';

class TTSEngineInitializationException implements Exception {
  final String message;
  final Object? cause;

  const TTSEngineInitializationException(this.message, [this.cause]);

  @override
  String toString() => cause == null
      ? 'TTSEngineInitializationException: $message'
      : 'TTSEngineInitializationException: $message ($cause)';
}

class TTSSynthesisException implements Exception {
  final String message;
  final Object? cause;

  const TTSSynthesisException(this.message, [this.cause]);

  @override
  String toString() => cause == null
      ? 'TTSSynthesisException: $message'
      : 'TTSSynthesisException: $message ($cause)';
}

/// Interface abstrata imutável para Motores de Inferência Neural Text-to-Speech (TTS).
///
/// Define o contrato fundamental que garante modularidade e possibilita a substituição
/// de motores (ex: Sherpa-onnx, Piper, Mock/Test) sem alterar os módulos superiores.
abstract class ITTSEngine {
  /// Configuração ativa da engine.
  TTSConfig get config;

  /// Retorna `true` se o motor de inferência e o modelo ONNX já foram inicializados.
  bool get isInitialized;

  /// Inicializa a engine e carrega o modelo em memória RAM/VRAM.
  Future<void> initialize();

  /// Sintetiza um texto em um buffer de amostras de áudio [AudioBuffer].
  Future<AudioBuffer> synthesize(String text);

  /// Sintetiza o texto e retorna o áudio acompanhado das métricas de RTF.
  Future<({AudioBuffer audio, PerformanceMetrics metrics})>
  synthesizeWithMetrics(String text) async {
    final result = await RTFCalculator.trackExecution<AudioBuffer>(
      action: () => synthesize(text),
      extractAudio: (audio) => audio,
    );
    return (audio: result.result, metrics: result.metrics);
  }

  /// Libera os recursos alocados pelo modelo ONNX em memória.
  Future<void> dispose();
}
