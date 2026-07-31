import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/engine/onnx_model_detector.dart';

void main() {
  group('OnnxModelDetector - Testes Unitários de Detecção de Modelos', () {
    test('detecta MMS e Piper por metadados confiáveis', () {
      final String mmsTokens = List.generate(
        50,
        (index) => '$index token_$index',
      ).join('\n');
      final String piperTokens = List.generate(
        250,
        (index) => '$index phoneme_$index',
      ).join('\n');

      final mmsType = OnnxModelDetector.detectFromTokensContent(
        mmsTokens,
        modelType: 'mms',
        hasEspeak: false,
      );
      final piperType = OnnxModelDetector.detectFromTokensContent(
        piperTokens,
        modelType: 'vits',
        comment: 'piper',
        hasEspeak: true,
      );

      expect(mmsType, equals(OnnxModelType.mmsCharacter));
      expect(piperType, equals(OnnxModelType.piperPhoneme));

      expect(OnnxModelDetector.requiresEspeakData(mmsType), isFalse);
      expect(OnnxModelDetector.requiresEspeakData(piperType), isTrue);
    });

    test('classifica o tokens.txt Faber de 152 linhas como Piper', () async {
      final tokens = await File('assets/models/tokens.txt').readAsString();

      final type = OnnxModelDetector.detectFromTokensContent(
        tokens,
        modelType: 'vits',
        comment: 'piper',
        hasEspeak: true,
      );

      expect(type, OnnxModelType.piperPhoneme);
      expect(OnnxModelDetector.requiresEspeakData(type), isTrue);
    });

    test('Deve detectar a taxa de amostragem padrão por caminho do modelo', () {
      expect(
        OnnxModelDetector.detectSampleRate('pt_BR-faber-medium.onnx'),
        equals(22050),
      );
      expect(
        OnnxModelDetector.detectSampleRate('kokoro-v1.onnx'),
        equals(24000),
      );
      expect(
        OnnxModelDetector.detectSampleRate('mms-por-16k.onnx'),
        equals(16000),
      );
    });
  });
}
