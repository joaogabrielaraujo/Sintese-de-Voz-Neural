import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/system/android_system_tts_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidSystemTtsBridge - Testes Unitários do Canal Nativo Android', () {
    test('Deve retornar false em plataformas desktop sem lançar exceção', () async {
      final bool updated = await AndroidSystemTtsBridge.updateActiveModelConfig(
        modelPath: 'pt_BR-faber-medium.onnx',
        tokensPath: 'tokens.txt',
        sampleRate: 22050,
      );

      expect(updated, isFalse);
    });

    test('Deve verificar disponibilidade do serviço sem lançar erro', () async {
      final bool available = await AndroidSystemTtsBridge.isServiceAvailable();
      expect(available, isFalse);
    });
  });
}
