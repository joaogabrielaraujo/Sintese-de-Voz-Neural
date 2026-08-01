import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/pdf_parser.dart';
import 'package:tcc_tts_neural/core/document/txt_parser.dart';

void main() {
  group('TxtParser & PdfParser - Testes Unitários de Importação Multi-Formato', () {
    test('TxtParser deve converter arquivo TXT em EpubBook estruturado por parágrafos', () {
      const String rawTxt = '''
Capítulo 1: Introdução ao TCC

Este é o primeiro parágrafo de teste do leitor de documentos TXT.

Este é o segundo parágrafo de teste sobre inferência neural offline em Edge Computing.
''';

      final book = TxtParser.parseText(rawTxt, title: 'Livro TXT Teste');

      expect(book.title, equals('Livro TXT Teste'));
      expect(book.chapters.length, equals(1));
      expect(book.chapters.first.cleanText, contains('Capítulo 1'));
      expect(book.chapters.first.cleanText, contains('Edge Computing'));
    });

    test('PdfParser deve sanitizar marcações de página de documentos PDF', () {
      const String rawPdfText = '''
Página 1
Relatório do Projeto de Síntese de Voz.
Page 2
Este é o texto limpo do capítulo do PDF.
- 3 -
Final da leitura.
''';

      final String sanitized = PdfParser.sanitizePdfText(rawPdfText);

      expect(sanitized, contains('Relatório do Projeto de Síntese de Voz.'));
      expect(sanitized, contains('Este é o texto limpo do capítulo do PDF.'));
      expect(sanitized.contains('Página 1'), isFalse);
      expect(sanitized.contains('Page 2'), isFalse);

      final book = PdfParser.parsePdfText(rawPdfText, title: 'Artigo PDF');
      expect(book.title, equals('Artigo PDF'));
      expect(book.chapters.first.cleanText.isNotEmpty, isTrue);
    });
  });
}
