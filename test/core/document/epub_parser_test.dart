import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/document/epub_model.dart';
import 'package:tcc_tts_neural/core/document/epub_parser.dart';

void main() {
  group('EpubParser - Testes de Integração de Parsing de EPUB', () {
    test('Deve extrair metadados e o Capítulo 1 a partir da estrutura EPUB', () {
      final Map<String, String> mockEpub = {
        'META-INF/container.xml': '''
          <?xml version="1.0"?>
          <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
              <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
          </container>
        ''',
        'OEBPS/content.opf': '''
          <?xml version="1.0" encoding="utf-8"?>
          <package xmlns="http://www.idpf.org/2007/opf" version="3.0">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
              <dc:title>Leitura Neural Offline</dc:title>
              <dc:creator>João Gabriel</dc:creator>
              <dc:language>pt-BR</dc:language>
            </metadata>
            <manifest>
              <item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
              <item id="chap2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
              <itemref idref="chap1"/>
              <itemref idref="chap2"/>
            </spine>
          </package>
        ''',
        'OEBPS/chapter1.xhtml': '''
          <html xmlns="http://www.w3.org/1999/xhtml">
            <body>
              <h1>Capítulo 1: O Início</h1>
              <p>Este é o texto limpo do primeiro capítulo do EPUB real.</p>
            </body>
          </html>
        ''',
        'OEBPS/chapter2.xhtml': '''
          <html xmlns="http://www.w3.org/1999/xhtml">
            <body>
              <h1>Capítulo 2: A Continuação</h1>
              <p>Texto do segundo capítulo do livro.</p>
            </body>
          </html>
        ''',
      };

      final EpubBook book = EpubParser.parseArchive(mockEpub);

      expect(book.title, equals('Leitura Neural Offline'));
      expect(book.author, equals('João Gabriel'));
      expect(book.totalChapters, equals(2));

      final EpubChapter? chap1 = book.chapterOne;
      expect(chap1, isNotNull);
      expect(chap1!.title, equals('Capítulo 1: O Início'));
      expect(chap1.cleanText, contains('Este é o texto limpo do primeiro capítulo do EPUB real.'));
    });
  });
}
