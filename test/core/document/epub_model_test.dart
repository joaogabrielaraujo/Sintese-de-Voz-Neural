import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';

void main() {
  group('EpubModel - Testes Unitários de EpubBook e EpubChapter', () {
    test('Deve instanciar EpubChapter com metadados e contagem de palavras', () {
      const chapter = EpubChapter(
        index: 0,
        id: 'chap1.xhtml',
        title: 'Capítulo 1: A Descoberta',
        rawHtml: '<p>Este é o primeiro capítulo do livro.</p>',
        cleanText: 'Este é o primeiro capítulo do livro.',
      );

      expect(chapter.index, equals(0));
      expect(chapter.title, equals('Capítulo 1: A Descoberta'));
      expect(chapter.wordCount, equals(7));
      expect(chapter.characterCount, equals(36));
    });

    test('Deve retornar chapterOne corretamente em EpubBook', () {
      const c1 = EpubChapter(
        index: 0,
        id: 'c1.xhtml',
        title: 'Introdução',
        rawHtml: '<h1>Intro</h1>',
        cleanText: 'Bem vindo ao livro de testes.',
      );
      const c2 = EpubChapter(
        index: 1,
        id: 'c2.xhtml',
        title: 'Capítulo 2',
        rawHtml: '<h1>Cap 2</h1>',
        cleanText: 'Conteúdo do segundo capítulo.',
      );

      const book = EpubBook(
        title: 'Livro de TCC',
        author: 'João Gabriel',
        chapters: [c1, c2],
      );

      expect(book.totalChapters, equals(2));
      expect(book.chapterOne, equals(c1));
      expect(book.totalWords, equals(6 + 4));
    });
  });
}
