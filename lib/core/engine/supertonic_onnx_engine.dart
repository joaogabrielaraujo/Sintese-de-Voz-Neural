import 'dart:async';
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

class _SupertonicWorker {
  final Isolate isolate;
  final ReceivePort receivePort;
  final SendPort sendPort;
  final Map<int, Completer<Object?>> pending = {};
  int nextRequestId = 1;

  _SupertonicWorker({
    required this.isolate,
    required this.receivePort,
    required this.sendPort,
  });
}

/// Offline Supertonic 3 engine backed by sherpa-onnx running in a background Isolate.
class SupertonicOnnxEngine extends ITTSEngine {
  final SupertonicConfig supertonicConfig;

  @override
  final TTSConfig config;

  bool _initialized = false;
  _SupertonicWorker? _worker;

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
    final receivePort = ReceivePort();
    final workerPortCompleter = Completer<SendPort>();
    late final StreamSubscription<Object?> subscription;
    subscription = receivePort.listen((message) {
      if (message is SendPort && !workerPortCompleter.isCompleted) {
        workerPortCompleter.complete(message);
      }
    });

    try {
      final isolate = await Isolate.spawn(
        _workerMain,
        receivePort.sendPort,
        debugName: 'supertonic-onnx-worker',
      );
      final sendPort = await workerPortCompleter.future;
      await subscription.cancel();
      receivePort.listen(_handleWorkerMessage);
      final worker = _SupertonicWorker(
        isolate: isolate,
        receivePort: receivePort,
        sendPort: sendPort,
      );
      _worker = worker;
      await _requestWorker(worker, {
        'type': 'init',
        'modelDirectory': supertonicConfig.modelDirectory,
        'nativeLibraryDirectory': supertonicConfig.nativeLibraryDirectory,
        'language': supertonicConfig.language,
        'speakerId': supertonicConfig.speakerId,
        'speed': supertonicConfig.speed,
        'numSteps': supertonicConfig.numSteps,
        'numThreads': supertonicConfig.numThreads,
      });
      _initialized = true;
    } catch (error) {
      await subscription.cancel();
      receivePort.close();
      rethrow;
    }
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

    try {
      final worker = _worker;
      if (worker == null) {
        throw const TTSSynthesisException('Worker Supertonic não inicializado.');
      }
      final result = await _requestWorker(worker, {
        'type': 'synthesize',
        'text': text,
        'language': supertonicConfig.language,
        'speakerId': supertonicConfig.speakerId,
        'speed': supertonicConfig.speed,
        'numSteps': supertonicConfig.numSteps,
      });
      final audioData = result as _SupertonicAudioData;
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

  Future<Object?> _requestWorker(
    _SupertonicWorker worker,
    Map<String, Object?> command,
  ) {
    final id = worker.nextRequestId++;
    final completer = Completer<Object?>();
    worker.pending[id] = completer;
    worker.sendPort.send({...command, 'id': id});
    return completer.future;
  }

  void _handleWorkerMessage(Object? message) {
    if (message is! List || message.length < 2) return;
    final id = message[0] as int;
    final completer = _worker?.pending.remove(id);
    if (completer == null || completer.isCompleted) return;
    if (message[1] == true && message.length >= 4) {
      completer.complete(_SupertonicAudioData(
        samples: message[2] as Float32List,
        sampleRate: message[3] as int,
      ));
    } else if (message[1] == true) {
      completer.complete(true);
    } else {
      completer.completeError(
        TTSSynthesisException(message.length >= 3 ? '${message[2]}' : 'Falha no worker Supertonic.'),
      );
    }
  }

  static Future<void> _workerMain(SendPort parentPort) async {
    final commands = ReceivePort();
    parentPort.send(commands.sendPort);
    sherpa.OfflineTts? tts;
    final nativeHandles = <DynamicLibrary>[];
    commands.listen((raw) {
      final command = Map<String, Object?>.from(raw as Map);
      final id = command['id'] as int;
      try {
        switch (command['type']) {
          case 'init':
            final params = _SupertonicIsolateParams(
              modelDirectory: command['modelDirectory'] as String,
              nativeLibraryDirectory: command['nativeLibraryDirectory'] as String?,
              language: command['language'] as String,
              speakerId: command['speakerId'] as int,
              speed: command['speed'] as double,
              numSteps: command['numSteps'] as int,
              numThreads: command['numThreads'] as int,
              text: '',
            );
            tts = _createTts(params, nativeHandles);
            parentPort.send([id, true]);
          case 'synthesize':
            if (tts == null) throw StateError('Runtime Supertonic não inicializado.');
            final params = _SupertonicIsolateParams(
              modelDirectory: '',
              nativeLibraryDirectory: null,
              language: command['language'] as String,
              speakerId: command['speakerId'] as int,
              speed: command['speed'] as double,
              numSteps: command['numSteps'] as int,
              numThreads: 1,
              text: command['text'] as String,
            );
            final audio = tts!.generateWithConfig(
              text: params.text,
              config: sherpa.OfflineTtsGenerationConfig(
                sid: params.speakerId,
                speed: params.speed,
                numSteps: params.numSteps,
                extra: {'lang': params.language, 'num_steps': params.numSteps},
              ),
            );
            if (audio.samples.isEmpty || audio.sampleRate <= 0) {
              throw StateError('Supertonic retornou áudio vazio.');
            }
            parentPort.send([id, true, audio.samples, audio.sampleRate]);
          case 'dispose':
            tts?.free();
            tts = null;
            parentPort.send([id, true]);
            commands.close();
        }
      } catch (error) {
        parentPort.send([id, false, '$error']);
      }
    });
  }

  static sherpa.OfflineTts _createTts(
    _SupertonicIsolateParams params,
    List<DynamicLibrary> nativeHandles,
  ) {
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

    return tts;
  }

  @override
  Future<void> dispose() async {
    final worker = _worker;
    _worker = null;
    if (worker != null) {
      try {
        await _requestWorker(worker, {'type': 'dispose'});
      } catch (_) {
        worker.isolate.kill(priority: Isolate.immediate);
      }
      worker.receivePort.close();
      worker.isolate.kill(priority: Isolate.beforeNextEvent);
    }
    _initialized = false;
  }
}
