import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Motor de Inferência Neural VITS (ONNX) Local que carrega os modelos de assets/models/.
///
/// Lê o modelo ONNX `pt_BR-faber-medium.onnx` (63.2MB) e o dicionário `tokens.txt`
/// para realizar a síntese neural em memória (Edge Computing).
class VitsOnnxEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  VitsOnnxEngine({TTSConfig? config})
    : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => false;

  @override
  Future<void> initialize() async {
    throw const TTSEngineInitializationException(
      'VitsOnnxEngine has no ONNX Runtime session and is disabled to prevent fabricated silent audio.',
    );
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    throw const TTSSynthesisException(
      'VitsOnnxEngine is disabled because it does not perform ONNX inference.',
    );
  }

  @override
  Future<void> dispose() async {
    // No resources are allocated while no runtime implementation exists.
  }
}
