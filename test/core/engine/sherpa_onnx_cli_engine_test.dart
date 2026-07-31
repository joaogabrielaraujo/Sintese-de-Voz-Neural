import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/sherpa_onnx_cli_engine.dart';

void main() {
  test('runs the CLI directly with exact Piper arguments', () async {
    final temp = await Directory.systemTemp.createTemp('sherpa_cli_test_');
    addTearDown(() => temp.delete(recursive: true));
    final sourceModel = File('${temp.path}/source.onnx')..writeAsBytesSync([1]);
    final sourceTokens = File('${temp.path}/source.tokens')
      ..writeAsStringSync('_ 0');
    final espeak = Directory('${temp.path}/espeak-ng-data')..createSync();
    File('${espeak.path}/phontab').writeAsBytesSync([1]);
    final extracted = Directory('${temp.path}/extracted');
    List<String>? capturedArguments;
    bool? capturedRunInShell;

    final engine = SherpaOnnxCliEngine(
      config: TTSConfig(
        modelPath: sourceModel.path,
        tokensPath: sourceTokens.path,
        espeakDataPath: espeak.path,
      ),
      customCliPath: Platform.resolvedExecutable,
      modelDirectory: extracted,
      processRunner: (executable, arguments, {required runInShell}) async {
        capturedArguments = List<String>.from(arguments);
        capturedRunInShell = runInShell;
        final outputArgument = arguments.singleWhere(
          (argument) => argument.startsWith('--output-filename='),
        );
        final outputPath = outputArgument.substring(
          '--output-filename='.length,
        );
        await File(outputPath).writeAsBytes(
          WavWriter.encodeToWav(
            AudioBuffer(
              samples: Float32List.fromList([0.1, -0.1]),
              sampleRate: 22050,
            ),
          ),
        );
        return ProcessResult(1, 0, '', '');
      },
    );

    await engine.initialize();
    final audio = await engine.synthesize('texto & não comando');

    expect(capturedRunInShell, isFalse);
    expect(
      capturedArguments,
      contains('--vits-model=${extracted.path}\\pt_BR-faber-medium.onnx'),
    );
    expect(
      capturedArguments,
      contains('--vits-tokens=${extracted.path}\\tokens.txt'),
    );
    expect(
      capturedArguments,
      contains('--vits-data-dir=${espeak.absolute.path}'),
    );
    expect(capturedArguments!.last, 'texto & nao comando');
    expect(audio.samples.any((sample) => sample != 0), isTrue);
    await engine.dispose();
  });
}
