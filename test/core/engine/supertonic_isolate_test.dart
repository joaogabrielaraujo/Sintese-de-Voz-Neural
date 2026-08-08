import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/supertonic_config.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/supertonic_onnx_engine.dart';

void main() {
  test('SupertonicOnnxEngine synthesizes in background isolate without freezing main thread', () async {
    final modelDir = Directory(
      '.planning/tmp/supertonic-extracted/sherpa-onnx-supertonic-3-tts-int8-2026-05-11',
    ).absolute;
    final dllDir = Directory(
      '.planning/tmp/win-x64-shared-release/sherpa-onnx-v1.13.4-win-x64-shared-MD-Release-lib/lib',
    ).absolute;

    final supertonicConfig = SupertonicConfig(
      modelDirectory: modelDir.path,
      nativeLibraryDirectory: dllDir.path,
    );

    expect(supertonicConfig.isInstalled, isTrue);

    final engine = SupertonicOnnxEngine(
      supertonicConfig: supertonicConfig,
      config: TTSConfig.defaultPtBr(),
    );

    await engine.initialize();
    final audio = await engine.synthesize('Testando isolamento de thread para nao travar a interface.');

    expect(audio.samples.isNotEmpty, isTrue);
    expect(audio.durationInSeconds, greaterThan(0.5));
    await engine.dispose();
  });
}
