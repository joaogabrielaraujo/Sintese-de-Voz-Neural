import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/text/tts_normalizer.dart';

const _corpus = <String>[
  'Olá! Esta é uma demonstração de síntese de voz em português brasileiro.',
  'Em 7 de agosto de 2026, o projeto VozLume custou R\$ 150,00?',
  'A UEFS fica em Feira de Santana, Bahia; João lê um capítulo por vez.',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
        'Uso: dart run tool/supertonic3_poc.dart <diretório-do-modelo>');
    exitCode = 64;
    return;
  }

  final modelPathArgument = args.first;
  final options = _parseOptions(args.skip(1));
  final speed = options['speed'] as double;
  final numSteps = options['numSteps'] as int;
  final numThreads = options['numThreads'] as int;

  final modelDir = Directory(modelPathArgument).absolute;
  final outputDir = Directory('.planning/tmp/supertonic-poc-output').absolute;
  final required = <String, String>{
    'durationPredictor': 'duration_predictor.int8.onnx',
    'textEncoder': 'text_encoder.int8.onnx',
    'vectorEstimator': 'vector_estimator.int8.onnx',
    'vocoder': 'vocoder.int8.onnx',
    'ttsJson': 'tts.json',
    'unicodeIndexer': 'unicode_indexer.bin',
    'voiceStyle': 'voice.bin',
  };

  final paths = <String, String>{};
  for (final entry in required.entries) {
    final file =
        File('${modelDir.path}${Platform.pathSeparator}${entry.value}');
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw FileSystemException('Componente ausente ou vazio', file.path);
    }
    paths[entry.key] = file.path;
  }

  outputDir.createSync(recursive: true);
  final nativeLibraryDirectory = Platform.environment['SHERPA_ONNX_DLL_DIR'];
  final nativeHandles = <DynamicLibrary>[];
  if (Platform.isWindows && nativeLibraryDirectory != null) {
    for (final name in const [
      'mbrola.dll',
      'onnxruntime.dll',
      'onnxruntime_providers_shared.dll',
    ]) {
      nativeHandles.add(
        DynamicLibrary.open(
          '$nativeLibraryDirectory${Platform.pathSeparator}$name',
        ),
      );
    }
  }
  sherpa.initBindings(nativeLibraryDirectory);
  final tts = sherpa.OfflineTts(
    sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        supertonic: sherpa.OfflineTtsSupertonicModelConfig(
          durationPredictor: paths['durationPredictor']!,
          textEncoder: paths['textEncoder']!,
          vectorEstimator: paths['vectorEstimator']!,
          vocoder: paths['vocoder']!,
          ttsJson: paths['ttsJson']!,
          unicodeIndexer: paths['unicodeIndexer']!,
          voiceStyle: paths['voiceStyle']!,
        ),
        numThreads: numThreads,
        debug: false,
        provider: 'cpu',
      ),
    ),
  );

  final results = <Map<String, Object>>[];
  try {
    for (var index = 0; index < _corpus.length; index++) {
      final rawText = _corpus[index];
      final normalizedText = TTSNormalizer.normalize(rawText);
      stdout.writeln('Sintetizando Amostra ${index + 1}:');
      stdout.writeln('  Bruto: "$rawText"');
      stdout.writeln('  Normalizado: "$normalizedText"');

      final stopwatch = Stopwatch()..start();
      final audio = tts.generateWithConfig(
        text: normalizedText,
        config: sherpa.OfflineTtsGenerationConfig(
          sid: 0,
          speed: speed,
          numSteps: numSteps,
          extra: {'lang': 'pt', 'num_steps': numSteps},
        ),
      );
      stopwatch.stop();
      if (audio.samples.isEmpty || audio.sampleRate <= 0) {
        throw StateError(
            'Supertonic produziu áudio vazio para a amostra $index.');
      }
      final buffer = AudioBuffer(
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      final output = File(
          '${outputDir.path}${Platform.pathSeparator}pt_br_${index + 1}.wav');
      await output.writeAsBytes(WavWriter.encodeToWav(buffer), flush: true);
      final synthesisSeconds = stopwatch.elapsedMicroseconds / 1000000;
      results.add({
        'sample': index + 1,
        'rawText': rawText,
        'normalizedText': normalizedText,
        'wav': output.path,
        'sampleRate': buffer.sampleRate,
        'audioSeconds': buffer.durationInSeconds,
        'synthesisSeconds': synthesisSeconds,
        'rtf': synthesisSeconds / buffer.durationInSeconds,
      });
    }
  } finally {
    tts.free();
    // Keep dependency handles alive until the Sherpa runtime is released.
    nativeHandles.clear();
  }

  final report = File('${outputDir.path}${Platform.pathSeparator}metrics.json');
  await report.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'modelDirectory': modelDir.path,
      'language': 'pt',
      'speakerId': 0,
      'speed': speed,
      'numSteps': numSteps,
      'numThreads': numThreads,
      'normalized': true,
      'results': results,
    }),
    flush: true,
  );
  stdout.writeln(await report.readAsString());
}

Map<String, Object> _parseOptions(Iterable<String> arguments) {
  var speed = 1.0;
  var numSteps = 6;
  var numThreads = 4;

  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (separator <= 2 || !argument.startsWith('--')) {
      throw FormatException('Opção inválida: $argument');
    }
    final key = argument.substring(2, separator);
    final value = argument.substring(separator + 1);
    switch (key) {
      case 'speed':
        speed = double.parse(value);
        if (speed <= 0) throw FormatException('speed deve ser positivo');
      case 'num-steps':
        numSteps = int.parse(value);
        if (numSteps <= 0) throw FormatException('num-steps deve ser positivo');
      case 'num-threads':
        numThreads = int.parse(value);
        if (numThreads <= 0) {
          throw FormatException('num-threads deve ser positivo');
        }
      default:
        throw FormatException('Opção desconhecida: --$key');
    }
  }

  return {
    'speed': speed,
    'numSteps': numSteps,
    'numThreads': numThreads,
  };
}
