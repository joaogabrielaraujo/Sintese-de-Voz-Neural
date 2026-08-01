import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/sherpa_onnx_engine.dart';
import 'package:tcc_tts_neural/core/engine/tts_engine_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'does not report initialization success when runtime data is absent',
    () async {
      final engine = SherpaOnnxTTSEngine(
        config: const TTSConfig(
          modelPath: 'missing/model.onnx',
          tokensPath: 'missing/tokens.txt',
        ),
      );

      await expectLater(
        engine.initialize(),
        throwsA(isA<TTSEngineInitializationException>()),
      );
      expect(engine.isInitialized, isFalse);
      await engine.dispose();
    },
  );
}
