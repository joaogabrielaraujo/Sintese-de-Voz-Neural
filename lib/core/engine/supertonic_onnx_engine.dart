import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../audio/wav_writer.dart';
import '../config/supertonic_config.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Offline Supertonic 3 engine backed by sherpa-onnx.
class SupertonicOnnxEngine extends ITTSEngine {
  final SupertonicConfig supertonicConfig;

  @override
  final TTSConfig config;

  sherpa.OfflineTts? _tts;
  final List<DynamicLibrary> _nativeHandles = [];

  SupertonicOnnxEngine({
    required this.supertonicConfig,
    TTSConfig? config,
  }) : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _tts != null;

  @override
  Future<void> initialize() async {
    if (isInitialized) return;
    final missing = supertonicConfig.missingFiles;
    if (missing.isNotEmpty) {
      throw TTSEngineInitializationException(
        'Instalação Supertonic incompleta. Arquivos ausentes: ${missing.join(', ')}.',
      );
    }

    try {
      _preloadWindowsDependencies();
      sherpa.initBindings(supertonicConfig.nativeLibraryDirectory);
      final directory = supertonicConfig.modelDirectory;
      String modelPath(String name) =>
          '$directory${Platform.pathSeparator}$name';
      _tts = sherpa.OfflineTts(
        sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            supertonic: sherpa.OfflineTtsSupertonicModelConfig(
              durationPredictor: modelPath('duration_predictor.int8.onnx'),
              textEncoder: modelPath('text_encoder.int8.onnx'),
              vectorEstimator: modelPath('vector_estimator.int8.onnx'),
              vocoder: modelPath('vocoder.int8.onnx'),
              ttsJson: modelPath('tts.json'),
              unicodeIndexer: modelPath('unicode_indexer.bin'),
              voiceStyle: modelPath('voice.bin'),
            ),
            numThreads: supertonicConfig.numThreads,
            debug: false,
            provider: 'cpu',
          ),
        ),
      );
    } on Object catch (error) {
      await dispose();
      throw TTSEngineInitializationException(
        'Não foi possível inicializar o Supertonic 3.',
        error,
      );
    }
  }

  void _preloadWindowsDependencies() {
    final directory = supertonicConfig.nativeLibraryDirectory;
    if (!Platform.isWindows || directory == null || _nativeHandles.isNotEmpty) {
      return;
    }
    for (final name in const [
      'mbrola.dll',
      'onnxruntime.dll',
      'onnxruntime_providers_shared.dll',
    ]) {
      _nativeHandles.add(
        DynamicLibrary.open('$directory${Platform.pathSeparator}$name'),
      );
    }
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (text.trim().isEmpty) {
      return AudioBuffer(
          samples: Float32List(0), sampleRate: config.sampleRate);
    }
    if (!isInitialized) await initialize();
    try {
      final audio = _tts!.generateWithConfig(
        text: text,
        config: sherpa.OfflineTtsGenerationConfig(
          sid: supertonicConfig.speakerId,
          speed: supertonicConfig.speed,
          numSteps: supertonicConfig.numSteps,
          extra: {
            'lang': supertonicConfig.language,
            'num_steps': supertonicConfig.numSteps,
          },
        ),
      );
      if (audio.samples.isEmpty || audio.sampleRate <= 0) {
        throw const TTSSynthesisException('Supertonic retornou áudio vazio.');
      }
      return AudioBuffer(samples: audio.samples, sampleRate: audio.sampleRate);
    } on TTSSynthesisException {
      rethrow;
    } on Object catch (error) {
      throw TTSSynthesisException('Falha na síntese Supertonic.', error);
    }
  }

  @override
  Future<void> dispose() async {
    _tts?.free();
    _tts = null;
    _nativeHandles.clear();
  }
}
