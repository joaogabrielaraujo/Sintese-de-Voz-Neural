import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../audio/wav_writer.dart';
import '../config/supertonic_config.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

class _SupertonicIsolateParams {
  final String modelDirectory;
  final String? nativeLibraryDirectory;
  final String language;
  final int speakerId;
  final double speed;
  final int numSteps;
  final int numThreads;
  final String text;

  const _SupertonicIsolateParams({
    required this.modelDirectory,
    this.nativeLibraryDirectory,
    required this.language,
    required this.speakerId,
    required this.speed,
    required this.numSteps,
    required this.numThreads,
    required this.text,
  });
}

class _SupertonicAudioData {
  final Float32List samples;
  final int sampleRate;

  const _SupertonicAudioData({
    required this.samples,
    required this.sampleRate,
  });
}

/// Offline Supertonic 3 engine backed by sherpa-onnx running in a background Isolate.
class SupertonicOnnxEngine extends ITTSEngine {
  final SupertonicConfig supertonicConfig;

  @override
  final TTSConfig config;

  bool _initialized = false;

  SupertonicOnnxEngine({
    required this.supertonicConfig,
    TTSConfig? config,
  }) : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (isInitialized) return;
    final missing = supertonicConfig.missingFiles;
    if (missing.isNotEmpty) {
      throw TTSEngineInitializationException(
        'Instalação Supertonic incompleta. Arquivos ausentes: ${missing.join(', ')}.',
      );
    }
    _initialized = true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (text.trim().isEmpty) {
      return AudioBuffer(
        samples: Float32List(0),
        sampleRate: config.sampleRate,
      );
    }
    if (!isInitialized) await initialize();

    final params = _SupertonicIsolateParams(
      modelDirectory: supertonicConfig.modelDirectory,
      nativeLibraryDirectory: supertonicConfig.nativeLibraryDirectory,
      language: supertonicConfig.language,
      speakerId: supertonicConfig.speakerId,
      speed: supertonicConfig.speed,
      numSteps: supertonicConfig.numSteps,
      numThreads: supertonicConfig.numThreads,
      text: text,
    );

    try {
      final audioData = await Isolate.run(() => _synthesizeInIsolate(params));
      return AudioBuffer(
        samples: audioData.samples,
        sampleRate: audioData.sampleRate,
      );
    } on TTSSynthesisException {
      rethrow;
    } on Object catch (error) {
      throw TTSSynthesisException('Falha na síntese Supertonic.', error);
    }
  }

  static _SupertonicAudioData _synthesizeInIsolate(
    _SupertonicIsolateParams params,
  ) {
    final nativeHandles = <DynamicLibrary>[];
    if (Platform.isWindows && params.nativeLibraryDirectory != null) {
      for (final name in const [
        'mbrola.dll',
        'onnxruntime.dll',
        'onnxruntime_providers_shared.dll',
      ]) {
        final dllPath =
            '${params.nativeLibraryDirectory}${Platform.pathSeparator}$name';
        if (File(dllPath).existsSync()) {
          nativeHandles.add(DynamicLibrary.open(dllPath));
        }
      }
    }
    sherpa.initBindings(params.nativeLibraryDirectory);
    final directory = params.modelDirectory;
    String modelPath(String name) => '$directory${Platform.pathSeparator}$name';

    final tts = sherpa.OfflineTts(
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
          numThreads: params.numThreads,
          debug: false,
          provider: 'cpu',
        ),
      ),
    );

    try {
      final audio = tts.generateWithConfig(
        text: params.text,
        config: sherpa.OfflineTtsGenerationConfig(
          sid: params.speakerId,
          speed: params.speed,
          numSteps: params.numSteps,
          extra: {
            'lang': params.language,
            'num_steps': params.numSteps,
          },
        ),
      );
      if (audio.samples.isEmpty || audio.sampleRate <= 0) {
        throw const TTSSynthesisException('Supertonic retornou áudio vazio.');
      }
      return _SupertonicAudioData(
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
    } finally {
      tts.free();
      nativeHandles.clear();
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = false;
  }
}
