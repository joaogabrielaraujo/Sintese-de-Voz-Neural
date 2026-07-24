# Contexto e Decisões de Arquitetura - Fase 4: Leitor & Extração de Texto EPUB (Parser XHTML/HTML)

## Objetivos da Fase
Desenvolver o módulo puramente funcional `lib/core/epub/` em Dart/Flutter para abrir contêineres digitais no formato `.epub` (arquivos ZIP estruturados em Open Packaging Format), extrair o arquivo manifesto (`content.opf`), resolver a ordem cronológica dos capítulos e sanitizar os documentos XHTML/HTML em texto corrido estruturado por capítulos, pronto para alimentação no Fatiador de Sentenças (Fase 3).

---

## Decisões de Arquitetura e Design

### 1. Estrutura de Leitura de EPUB (Open eBook Publication Structure)
- **Extração de Contêiner ZIP**: O formato `.epub` é um arquivo comprimido (PKZIP). O módulo descompacta o arquivo em memória ou fluxo de bytes.
- **Resolução do `container.xml`**: Localiza o ponteiro `<rootfile full-path="...">` apontando para o manifesto OPF principal.
- **Parsing do Manifesto OPF (`content.opf`)**:
  - Extrai metadados do livro: `title`, `author`, `language`.
  - Mapeia o elemento `<manifest>` (lista de itens XHTML pelo ID) e `<spine>` (ordem exata de leitura dos capítulos).
- **Limpeza de Tags XHTML/HTML**: Remoção de elementos não-textuais (CSS `<style>`, scripts `<script>`, tags de imagem `<img>` isolando o atributo `alt`, formatações de tabela) sem destruir quebras de parágrafo (`<p>`, `<div>`, `<br>`).

### 2. Modelos de Dados Imutáveis (`lib/core/epub/epub_model.dart`)
- **`EpubChapter`**:
  - `index`: Posição sequencial do capítulo.
  - `id`: Identificador interno (ex: `"chapter1.xhtml"`).
  - `title`: Título amigável extraído de cabeçalhos (`<h1>`-`<h3>`) ou do manifesto.
  - `rawHtml`: Conteúdo bruto em XHTML.
  - `cleanText`: Texto sanitizado limpo por parágrafos.
- **`EpubBook`**:
  - `title`: Título do livro.
  - `author`: Autor do livro.
  - `chapters`: Lista imutável de [EpubChapter].

### 3. Cobertura de Testes e Arquivos de Teste (Mocks & EPUB Real)
- Criação de um utilitário para gerar estruturas de bytes EPUB/ZIP de teste.
- Validação do fluxo completo: Abertura do EPUB -> Leitura do Capítulo 1 -> Extração de Texto Limpo sem tags HTML.
