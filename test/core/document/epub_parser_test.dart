import 'dart:typed_data';

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

    test('aceita atributos com aspas simples e fragmento no href', () {
      final book = EpubParser.parseArchive({
        'META-INF/container.xml':
            "<container><rootfile full-path='OPS/package.opf'/></container>",
        'OPS/package.opf': """
          <package><manifest>
            <item media-type='application/xhtml+xml' href='chapter.xhtml#inicio' id='chapter'/>
          </manifest><spine><itemref idref='chapter'/></spine></package>
        """,
        'OPS/chapter.xhtml': '<html><body><p>Texto acentuado: ação.</p></body></html>',
      });

      expect(book.chapters.single.cleanText, contains('ação'));
    });

    test('prioriza nav.xhtml e preserva imagem interna sem incluí-la na TTS', () {
      final book = EpubParser.parseArchive({
        'META-INF/container.xml': '<container><rootfile full-path="OPS/package.opf"/></container>',
        'OPS/package.opf': '<package><manifest>'
            '<item id="nav" properties="nav" href="nav.xhtml"/>'
            '<item id="chapter" href="text/chapter.xhtml"/>'
            '</manifest><spine><itemref idref="chapter"/></spine></package>',
        'OPS/nav.xhtml': '<nav><ol><li><a href="text/chapter.xhtml">Parte I — Abertura</a></li></ol></nav>',
        'OPS/text/chapter.xhtml': '<html><body><p>Antes da imagem.</p><img src="../images/figura.png" alt="descrição"/><p>Depois da imagem.</p></body></html>',
      }, resources: {
        'OPS/images/figura.png': Uint8List.fromList([137, 80, 78, 71]),
      });

      final chapter = book.chapters.single;
      expect(chapter.title, 'Parte I — Abertura');
      expect(chapter.cleanText, contains('Antes da imagem.'));
      expect(chapter.cleanText, contains('Depois da imagem.'));
      expect(chapter.cleanText, isNot(contains('descrição')));
      final image = chapter.contentBlocks.whereType<EpubImageBlock>().single;
      expect(image.resourcePath, 'OPS/images/figura.png');
      expect(image.bytes, [137, 80, 78, 71]);
    });

    test('rejeita OPF ausente em vez de voltar silenciosamente ao exemplo', () {
      expect(
        () => EpubParser.parseArchive({
          'META-INF/container.xml':
              '<container><rootfile full-path="OPS/missing.opf"/></container>',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('fatia arquivo XHTML unico em multiplas secoes baseadas em ancoras #id do toc.ncx', () {
      final book = EpubParser.parseArchive({
        'META-INF/container.xml': '<container><rootfile full-path="OEBPS/content.opf"/></container>',
        'OEBPS/content.opf': '''
          <package>
            <manifest>
              <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
              <item id="single_doc" href="book.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine toc="ncx">
              <itemref idref="single_doc"/>
            </spine>
          </package>
        ''',
        'OEBPS/toc.ncx': '''
          <ncx>
            <navMap>
              <navPoint id="np1">
                <navLabel><text>Seção 1: Introdução à Síntese</text></navLabel>
                <content src="book.xhtml#sec1"/>
              </navPoint>
              <navPoint id="np2">
                <navLabel><text>Seção 2: Arquitetura Neural</text></navLabel>
                <content src="book.xhtml#sec2"/>
              </navPoint>
            </navMap>
          </ncx>
        ''',
        'OEBPS/book.xhtml': '''
          <html>
            <body>
              <div id="sec1">
                <h1>Introdução à Síntese</h1>
                <p>Conteúdo da introdução sobre síntese de voz neural offline.</p>
              </div>
              <div id="sec2">
                <h1>Arquitetura Neural</h1>
                <p>Conteúdo detalhado sobre modelos ONNX e VITS.</p>
              </div>
            </body>
          </html>
        ''',
      });

      expect(book.totalChapters, equals(2));
      expect(book.chapters[0].title, equals('Seção 1: Introdução à Síntese'));
      expect(book.chapters[0].id, equals('OEBPS/book.xhtml#sec1'));
      expect(book.chapters[0].cleanText, contains('introdução sobre síntese de voz neural'));

      expect(book.chapters[1].title, equals('Seção 2: Arquitetura Neural'));
      expect(book.chapters[1].id, equals('OEBPS/book.xhtml#sec2'));
      expect(book.chapters[1].cleanText, contains('modelos ONNX e VITS'));
    });

    test('fatia HTML extenso com cabeçalhos h1/h2 na ausência de ancoras no sumario', () {
      final book = EpubParser.parseArchive({
        'META-INF/container.xml': '<container><rootfile full-path="OEBPS/content.opf"/></container>',
        'OEBPS/content.opf': '''
          <package>
            <manifest>
              <item id="big_doc" href="large.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
              <itemref idref="big_doc"/>
            </spine>
          </package>
        ''',
        'OEBPS/large.xhtml': '''
          <html>
            <body>
              <h1>Capítulo A: Fundamentos de Áudio</h1>
              <p>Texto detalhado da primeira parte do capítulo.</p>
              <h1>Capítulo B: Processamento Digital</h1>
              <p>Texto detalhado da segunda parte do capítulo.</p>
            </body>
          </html>
        ''',
      });

      expect(book.totalChapters, equals(2));
      expect(book.chapters[0].title, equals('Capítulo A: Fundamentos de Áudio'));
      expect(book.chapters[1].title, equals('Capítulo B: Processamento Digital'));
    });

    test('extrai imagem de capa dos metadados OPF e recursos', () {
      final book = EpubParser.parseArchive({
        'META-INF/container.xml': '<container><rootfile full-path="OEBPS/content.opf"/></container>',
        'OEBPS/content.opf': '''
          <package>
            <metadata>
              <meta name="cover" content="cover-img"/>
            </metadata>
            <manifest>
              <item id="cover-img" href="images/cover.jpg" media-type="image/jpeg"/>
              <item id="doc" href="chap.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
              <itemref idref="doc"/>
            </spine>
          </package>
        ''',
        'OEBPS/chap.xhtml': '<html><body><p>Conteúdo com capa.</p></body></html>',
      }, resources: {
        'OEBPS/images/cover.jpg': Uint8List.fromList([255, 216, 255, 224]),
      });

      expect(book.coverImageBytes, isNotNull);
      expect(book.coverImageBytes, equals(Uint8List.fromList([255, 216, 255, 224])));
    });
  });
}
