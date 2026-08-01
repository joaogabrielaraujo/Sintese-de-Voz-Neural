import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/text/sentence_model.dart';
import 'package:tcc_tts_neural/core/text/sentence_segmenter.dart';

void main() {
  group('SentenceSegmenter - Testes Unitários do Fatiador de Sentenças', () {
    test('Deve fatiar um parágrafo simples com pontuações finais (. ! ?)', () {
      const String text =
          'Primeira sentença aqui. Segunda sentença com exclamação! Terceira com pergunta?';

      final List<TextSentence> sentences = SentenceSegmenter.segment(text);

      expect(sentences.length, equals(3));
      expect(sentences[0].text, equals('Primeira sentença aqui.'));
      expect(sentences[1].text, equals('Segunda sentença com exclamação!'));
      expect(sentences[2].text, equals('Terceira com pergunta?'));
      expect(sentences[2].isParagraphEnd, isTrue);
    });

    test(
      'NÃO deve quebrar em pontos de abreviações conhecidas (Dr., Prof., pág.)',
      () {
        const String text =
            'O Dr. Matheus orienta o aluno na pág. 15. A defesa será na UEFS.';

        final List<TextSentence> sentences = SentenceSegmenter.segment(text);

        expect(sentences.length, equals(2));
        expect(
          sentences[0].text,
          equals('O Dr. Matheus orienta o aluno na pág. 15.'),
        );
        expect(sentences[1].text, equals('A defesa será na UEFS.'));
      },
    );

    test('Deve respeitar quebras de múltiplos parágrafos', () {
      const String text =
          'Parágrafo 1 sentença 1.\n\nParágrafo 2 sentença 1. Parágrafo 2 sentença 2.';

      final List<TextSentence> sentences = SentenceSegmenter.segment(text);

      expect(sentences.length, equals(3));
      expect(sentences[0].isParagraphEnd, isTrue);
      expect(sentences[1].isParagraphEnd, isFalse);
      expect(sentences[2].isParagraphEnd, isTrue);
    });

    test(
      'Deve realizar divisão suave (soft split) em frases muito longas com vírgulas',
      () {
        const String longSentence =
            'Esta é uma sentença extremamente longa e detalhada elaborada para testar o algoritmo de divisão suave, que previne o estouro de latência no motor de inferência neural quando o texto ultrapassa o limite de caracteres estipulado.';

        final List<TextSentence> sentences = SentenceSegmenter.segment(
          longSentence,
          maxSentenceLength: 100,
        );

        expect(sentences.length, greaterThan(1));
        expect(
          sentences.every((sentence) => sentence.text.length <= 100),
          isTrue,
        );
      },
    );

    test('respeita o limite sem delimitadores suaves', () {
      final text = List.filled(60, 'palavra').join(' ');

      final sentences = SentenceSegmenter.segment(text, maxSentenceLength: 80);

      expect(sentences.length, greaterThan(1));
      expect(sentences.every((sentence) => sentence.text.length <= 80), isTrue);
    });
  });
}
