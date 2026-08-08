import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/supertonic_config.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/composite_tts_engine.dart';
import 'package:tcc_tts_neural/core/engine/supertonic_onnx_engine.dart';
import 'package:tcc_tts_neural/core/engine/tts_engine_type.dart';

void main() {
  test('Supertonic 3 live synthesis and engine switching on Windows Desktop', () async {
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

    expect(supertonicConfig.isInstalled, isTrue,
        reason: 'Supertonic 3 int8 model directory should be present in .planning/tmp');

    final handles = <DynamicLibrary>[];
    for (final dllName in ['mbrola.dll', 'onnxruntime.dll', 'onnxruntime_providers_shared.dll']) {
      final dllPath = '${dllDir.path}${Platform.pathSeparator}$dllName';
      if (File(dllPath).existsSync()) {
        handles.add(DynamicLibrary.open(dllPath));
      }
    }

    final baseConfig = TTSConfig.defaultPtBr();
    final supertonicEngine = SupertonicOnnxEngine(
      config: baseConfig,
      supertonicConfig: supertonicConfig,
    );

    final composite = CompositeTTSEngine(
      config: baseConfig,
      supertonicEngine: supertonicEngine,
      initialType: TTSEngineType.supertonic,
    );

    try {
      await composite.initialize();
      expect(composite.activeType, TTSEngineType.supertonic);

      final audioSupertonic = await composite.synthesize('Teste de sintese neural expressiva');
      expect(audioSupertonic.samples.isNotEmpty, isTrue);
      expect(audioSupertonic.durationInSeconds, greaterThan(0.5));

      await composite.setEngineType(TTSEngineType.autoFailover);
      expect(composite.activeType, TTSEngineType.supertonic);

      await composite.setEngineType(TTSEngineType.supertonic);
      expect(composite.activeType, TTSEngineType.supertonic);

      final audioSecond = await composite.synthesize('Segunda frase sintetizada para testar integridade pos-troca.');
      expect(audioSecond.samples.isNotEmpty, isTrue);

      await composite.dispose();
      expect(supertonicEngine.isInitialized, isFalse);
    } finally {
      handles.clear();
    }
  });
}
