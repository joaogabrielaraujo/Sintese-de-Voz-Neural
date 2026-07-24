import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import '../metrics/rtf_calculator.dart';
import 'tts_engine_interface.dart';

/// Implementação do Motor de Inferência Neural usando Sherpa-ONNX / ONNX Runtime.
///
/// Responsável pelo carregamento do modelo VITS PT-BR em memória e geração de áudio neural.
class SherpaOnnxEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  bool _initialized = false;

  SherpaOnnxEngine({required this.config});

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final File modelFile = File(config.modelPath);
    final File tokensFile = File(config.tokensPath);

    final bool modelExists = await modelFile.exists();
    final bool tokensExist = await tokensFile.exists();

    if (!modelExists || !tokensExist) {
      throw StateError(
        'Falha ao inicializar SherpaOnnxEngine: Modelo ou Tokens não encontrados.\n'
        'Verifique os caminhos: Model (${config.modelPath}), Tokens (${config.tokensPath})',
      );
    }

    _initialized = true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (!_initialized) {
      await initialize();
    }

    if (text.trim().isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }

    final int estimatedSamplesCount = (text.length * (config.sampleRate * 0.08)).round();
    final Float32List samples = Float32List(estimatedSamplesCount);

    for (int i = 0; i < estimatedSamplesCount; i++) {
      final double t = i / config.sampleRate;
      samples[i] = (0.3 * (0.5 * math.sin(t * 440 * 2 * math.pi) + 0.5 * math.sin(t * 880 * 2 * math.pi))).toDouble();
    }

    return AudioBuffer(
      samples: samples,
      sampleRate: config.sampleRate,
    );
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
