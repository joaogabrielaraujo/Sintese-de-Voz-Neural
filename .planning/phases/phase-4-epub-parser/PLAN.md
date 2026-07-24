# Plano de Execução Detalhado - Fase 4: Leitor & Extração de Texto EPUB (Parser XHTML/HTML)

## Objetivo
Desenvolver o módulo puramente funcional `lib/core/epub/` em Dart/Flutter para abrir arquivos `.epub`, descompactar e extrair o texto limpo e estruturado por capítulos (`EpubBook` e `EpubChapter`), removendo formatações e tags XHTML sem alterar a coerência da leitura.

---

## Estrutura Modular Proposta

```
lib/core/epub/
├── epub_model.dart        # Modelos imutáveis EpubBook e EpubChapter
├── html_sanitizer.dart    # Sanitizador puramente funcional para converter XHTML em texto limpo
└── epub_parser.dart       # Extrator e parser de arquivos EPUB (container.xml, OPF, Spine)

test/core/epub/
├── html_sanitizer_test.dart # Testes do limpador de tags HTML/XHTML
└── epub_parser_test.dart    # Testes de integração de extração de EPUB real e simulado
```

---

## Tarefas de Execução (Slices Modulares)

### Tarefa 4.1: Modelos de Dados `EpubBook` e `EpubChapter` (`epub_model.dart`)
- **Descrição**: Desenvolver as classes imutáveis `EpubChapter` (com ID, título, texto limpo e contagem de palavras) e `EpubBook` (com título, autor, lista de capítulos e utilitário para busca do Capítulo 1).
- **Arquivos**: `lib/core/epub/epub_model.dart`, `test/core/epub/epub_model_test.dart`
- **Verificação**: Testes unitários para cálculo de totais de palavras, verificação de igualdade e representação de capítulo.

### Tarefa 4.2: Sanitizador de Tags HTML/XHTML (`html_sanitizer.dart`)
- **Descrição**: Desenvolver a classe `HtmlSanitizer` com expressões regulares e manipulador de árvore para remover `<style>`, `<script>`, comentários `<!-- -->`, extrair o texto de elementos `<p>`, `<h1>`-`<h6>`, `<div>`, `<br>` e converter entidades HTML (`&nbsp;`, `&amp;`, `&lt;`, `&gt;`, `&quot;`).
- **Arquivos**: `lib/core/epub/html_sanitizer.dart`, `test/core/epub/html_sanitizer_test.dart`
- **Verificação**: Testes unitários cobrindo fragmentos complexos de páginas XHTML de livros com formatações e estilizações incorporadas.

### Tarefa 4.3: Extrator e Parser de Contêiner EPUB (`epub_parser.dart`)
- **Descrição**: Desenvolver `EpubParser.parseBytes(Uint8List bytes)` e `EpubParser.parseFile(File file)` que:
  1. Descompacta a estrutura ZIP do EPUB.
  2. Lê `META-INF/container.xml` para localizar o manifesto `.opf`.
  3. Processa o arquivo `.opf` extraindo os metadados do livro e a ordem de capítulos definida na `<spine>`.
  4. Extrai cada arquivo de capítulo XHTML e gera um objeto `EpubChapter`.
- **Arquivos**: `lib/core/epub/epub_parser.dart`, `test/core/epub/epub_parser_test.dart`
- **Verificação**: Teste de integração criando um arquivo EPUB em memória e validando a extração do Capítulo 1.

### Tarefa 4.4: Integração com o Pipeline de Demonstração (`main.dart`)
- **Descrição**: Atualizar a interface do aplicativo Flutter `lib/main.dart` adicionando a funcionalidade de simulação/carregamento de arquivo EPUB, extração do Capítulo 1 e envio automático para o Fatiador de Sentenças (Fase 3), Normalizador PLN (Fase 2) e Inferência ONNX (Fase 1).
- **Arquivos**: `lib/main.dart`
- **Verificação**: Execução do fluxo completo ponta a ponta na UI de demonstração.

---

## Critérios de Aceite da Fase 4 (Verification Gate)
- [ ] O módulo `EpubParser` abre arquivos `.epub` e extrai os capítulos respeitando a ordem da `<spine>`.
- [ ] O sanitizador `HtmlSanitizer` limpa 100% das tags XHTML/HTML e converte entidades especiais sem perder o texto corrido.
- [ ] O Capítulo 1 de um livro EPUB pode ser extraído e enviado para o pipeline de fatiamento e síntese.
- [ ] A suíte de testes unitários da Fase 4 passa com 100% de sucesso.
