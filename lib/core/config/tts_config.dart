import 'package:flutter/foundation.dart';

/// Configuração imutável e centralizada para a Engine de Inferência Neural TTS (ONNX).
///
/// Mantém as definições de modelo, taxa de amostragem, número de threads
/// e caminhos de assets em um único local previsível.
@immutable
class TTSConfig {
  /// Caminho relativo ou absoluto do arquivo do modelo ONNX VITS.
  final String modelPath;

  /// Caminho do arquivo de tokens associado ao modelo VITS.
  final String tokensPath;

  /// Caminho opcional do arquivo léxico (dicionário fonético).
  final String? lexiconPath;

  /// Taxa de amostragem do áudio sintetizado em Hz (padrão: 22050 Hz).
  final int sampleRate;

  /// Número de threads de CPU alocadas para a execução da inferência ONNX.
  final int numThreads;

  /// Fator de escala de ruído (noise scale) para variação de entonação VITS.
  final double noiseScale;

  /// Fator de escala de duração (length scale) para velocidade da fala (1.0 = normal).
  final double lengthScale;

  /// Construtor imutável com validações padrão.
  const TTSConfig({
    required this.modelPath,
    required this.tokensPath,
    this.lexiconPath,
    this.sampleRate = 22050,
    this.numThreads = 2,
    this.noiseScale = 0.667,
    this.lengthScale = 1.0,
  })  : assert(sampleRate > 0, 'sampleRate deve ser maior que zero'),
        assert(numThreads > 0, 'numThreads deve ser no mínimo 1');

  /// Configuração padrão pré-definida para o modelo Português BR em ONNX.
  factory TTSConfig.defaultPtBr({
    String modelPath = 'assets/models/vits-piper-pt_BR-faber-medium.onnx',
    String tokensPath = 'assets/models/tokens.txt',
  }) {
    return TTSConfig(
      modelPath: modelPath,
      tokensPath: tokensPath,
      sampleRate: 22050,
      numThreads: 2,
      noiseScale: 0.667,
      lengthScale: 1.0,
    );
  }

  @override
  String toString() {
    return 'TTSConfig(modelPath: $modelPath, sampleRate: ${sampleRate}Hz, threads: $numThreads, speed: $lengthScale)';
  }
}
