import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/engine/mock_tts_engine.dart';

void main() {
  group('TTSEngine - Testes de Integração de Inferência Neural', () {
    late MockTTSEngine engine;

    setUp(() {
      engine = MockTTSEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('Deve inicializar o motor de inferência com sucesso', () async {
      expect(engine.isInitialized, isFalse);
      await engine.initialize();
      expect(engine.isInitialized, isTrue);
    });

    test('Deve sintetizar texto em Português e gerar amostras válidas de áudio', () async {
      const String text = 'Testando inferência de voz neural offline em Flutter.';
      
      final result = await engine.synthesizeWithMetrics(text);

      expect(result.audio.samples.isNotEmpty, isTrue);
      expect(result.audio.durationInSeconds, greaterThan(0.5));
      expect(result.metrics.rtf, lessThan(1.0));
      expect(result.metrics.isRealTime, isTrue);
    });

    test('Deve retornar buffer vazio para strings em branco', () async {
      final audio = await engine.synthesize('   ');
      expect(audio.samples.isEmpty, isTrue);
      expect(audio.durationInSeconds, equals(0.0));
    });
  });
}
