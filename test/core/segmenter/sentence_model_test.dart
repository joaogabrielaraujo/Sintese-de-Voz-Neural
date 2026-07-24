import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/segmenter/sentence_model.dart';

void main() {
  group('TextSentence - Testes Unitários do Modelo de Sentença', () {
    test('Deve instanciar TextSentence com valores corretos', () {
      const sentence = TextSentence(
        index: 0,
        text: 'Esta é uma sentença de teste.',
        isParagraphEnd: true,
      );

      expect(sentence.index, equals(0));
      expect(sentence.text, equals('Esta é uma sentença de teste.'));
      expect(sentence.isParagraphEnd, isTrue);
      expect(sentence.characterCount, equals(29));
      expect(sentence.wordCount, equals(6));
      expect(sentence.estimatedDurationSeconds, greaterThan(1.0));
    });

    test('Deve validar igualdade por valor', () {
      const s1 = TextSentence(index: 1, text: 'Olá', isParagraphEnd: false);
      const s2 = TextSentence(index: 1, text: 'Olá', isParagraphEnd: false);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });
}
