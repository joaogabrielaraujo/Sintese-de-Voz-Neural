import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';

void main() {
  group('TTSConfig - Testes Unitários de Configuração', () {
    test('Deve inicializar TTSConfig com valores padrão para PT-BR', () {
      final config = TTSConfig.defaultPtBr();

      expect(config.sampleRate, equals(22050));
      expect(config.numThreads, equals(4));
      expect(config.noiseScale, equals(0.85));
      expect(config.lengthScale, equals(1.12));
      expect(config.modelPath, contains('pt_BR-faber-medium.onnx'));
      expect(config.espeakDataPath, equals('assets/models/espeak-ng-data'));
    });

    test('Deve lançar AssertionError se sampleRate for menor ou igual a zero',
        () {
      expect(
        () => TTSConfig(
          modelPath: 'model.onnx',
          tokensPath: 'tokens.txt',
          sampleRate: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Deve lançar AssertionError se numThreads for menor que 1', () {
      expect(
        () => TTSConfig(
          modelPath: 'model.onnx',
          tokensPath: 'tokens.txt',
          numThreads: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
