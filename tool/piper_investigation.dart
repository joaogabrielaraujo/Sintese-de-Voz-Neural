import 'dart:ffi';
import 'dart:io';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/text/tts_normalizer.dart';

void main() async {
  final modelFile = File('models/pt_BR-faber-medium.onnx').absolute;
  final tokensFile = File('models/tokens.txt').absolute;
  final espeakDir = Directory('assets/models/espeak-ng-data').absolute;
  final outputDir = Directory('.planning/tmp/piper-investigation').absolute;

  stdout.writeln('=== Investigação de Qualidade e Entonação do Piper VITS (Faber PT-BR) ===');
  stdout.writeln('Modelo: ${modelFile.path}');
  stdout.writeln('Tokens: ${tokensFile.path}');
  stdout.writeln('EspeakData: ${espeakDir.path}');

  if (!modelFile.existsSync() || !tokensFile.existsSync() || !espeakDir.existsSync()) {
    stderr.writeln('ERRO: Arquivos do modelo Piper ausentes.');
    exitCode = 1;
    return;
  }

  final nativeLibraryDirectory = Platform.environment['SHERPA_ONNX_DLL_DIR'];
  if (Platform.isWindows && nativeLibraryDirectory != null) {
    for (final name in const [
      'mbrola.dll',
      'onnxruntime.dll',
      'onnxruntime_providers_shared.dll',
    ]) {
      final dllPath = '$nativeLibraryDirectory${Platform.pathSeparator}$name';
      if (File(dllPath).existsSync()) {
        DynamicLibrary.open(dllPath);
      }
    }
  }
  sherpa.initBindings(nativeLibraryDirectory);

  final sentences = [
    'Olá! Esta é uma demonstração da voz Piper Faber. Como você está se sentindo hoje?',
    'Em sete de agosto de dois mil e vinte e seis, o projeto VozLume atingiu alta fidelidade.',
    'A UEFS fica em Feira de Santana, Bahia; João lê um capítulo por vez.',
  ];

  // Testar combinações de noiseScale (modulação de tom) e lengthScale (ritmo/duração)
  final testConfigs = [
    {'name': 'config_default', 'noiseScale': 0.667, 'lengthScale': 1.0, 'noiseScaleW': 0.8},
    {'name': 'config_expressive_pitch', 'noiseScale': 0.85, 'lengthScale': 1.05, 'noiseScaleW': 0.9},
    {'name': 'config_high_intonation', 'noiseScale': 0.95, 'lengthScale': 1.10, 'noiseScaleW': 1.0},
  ];

  for (final cfg in testConfigs) {
    final name = cfg['name'] as String;
    final noiseScale = cfg['noiseScale'] as double;
    final lengthScale = cfg['lengthScale'] as double;
    final noiseScaleW = cfg['noiseScaleW'] as double;

    stdout.writeln('\n--- Testando $name (noiseScale: $noiseScale, lengthScale: $lengthScale, noiseScaleW: $noiseScaleW) ---');

    final tts = sherpa.OfflineTts(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: modelFile.path,
            tokens: tokensFile.path,
            lexicon: '',
            dataDir: espeakDir.path,
            noiseScale: noiseScale,
            noiseScaleW: noiseScaleW,
            lengthScale: lengthScale,
          ),
          numThreads: 4,
          debug: false,
          provider: 'cpu',
        ),
      ),
    );

    try {
      for (var i = 0; i < sentences.length; i++) {
        final raw = sentences[i];
        final norm = TTSNormalizer.normalize(raw);
        final sw = Stopwatch()..start();
        final audio = tts.generateWithConfig(
          text: norm,
          config: sherpa.OfflineTtsGenerationConfig(
            sid: 0,
            speed: 1.0,
          ),
        );
        sw.stop();

        final buffer = AudioBuffer(
          samples: audio.samples,
          sampleRate: audio.sampleRate,
        ).trimSilence();

        final outFile = File('${outputDir.path}${Platform.pathSeparator}${name}_sample_${i + 1}.wav');
        await outFile.writeAsBytes(WavWriter.encodeToWav(buffer), flush: true);

        final rtf = (sw.elapsedMilliseconds / 1000.0) / buffer.durationInSeconds;
        stdout.writeln('  [Amostra ${i + 1}] Áudio: ${buffer.durationInSeconds.toStringAsFixed(2)}s | Síntese: ${sw.elapsedMilliseconds}ms | RTF: ${rtf.toStringAsFixed(3)} -> ${outFile.path}');
      }
    } finally {
      tts.free();
    }
  }

  stdout.writeln('\n=== Testes concluídos com sucesso! Arquivos salvos em ${outputDir.path} ===');
}
