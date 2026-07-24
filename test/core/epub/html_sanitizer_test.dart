import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/epub/html_sanitizer.dart';

void main() {
  group('HtmlSanitizer - Testes Unitários de Sanitização XHTML/HTML', () {
    test('Deve remover tags HTML mantendo a estrutura de parágrafos', () {
      const String html = '''
        <html>
          <head><style>p { color: red; }</style></head>
          <body>
            <h1>Capítulo 1: O Início</h1>
            <p>Primeiro parágrafo de <b>exemplo</b>.</p>
            <p>Segundo parágrafo com &amp; caracteres especiais.</p>
          </body>
        </html>
      ''';

      final String clean = HtmlSanitizer.sanitize(html);

      expect(clean, contains('Capítulo 1: O Início'));
      expect(clean, contains('Primeiro parágrafo de exemplo.'));
      expect(clean, contains('Segundo parágrafo com & caracteres especiais.'));
      expect(clean, isNot(contains('<style>')));
      expect(clean, isNot(contains('<b>')));
    });

    test('Deve extrair o título do capítulo de tags h1', () {
      const String html = '<div><h1>Capítulo 1: A Jornada</h1><p>Texto</p></div>';
      final String title = HtmlSanitizer.extractTitle(html);

      expect(title, equals('Capítulo 1: A Jornada'));
    });
  });
}
