# Análise — Paginação fiel do EPUB

## Situação atual

O parser atual segue o `spine` e cria um `EpubChapter` com `rawHtml` e `cleanText`. O `HtmlSanitizer` remove as tags e mantém apenas parágrafos, portanto os marcadores de página do XHTML são descartados.

## O que significa “página original”

EPUBs de layout refluível não possuem necessariamente páginas fixas. Quando existem referências à edição impressa, elas normalmente aparecem como:

- `<span epub:type="pagebreak" ...>`;
- elementos com `role="doc-pagebreak"`;
- `<div class="page-break">` ou classes equivalentes;
- `page-list` no EPUB 3 Navigation Document;
- links `#page_...` no índice de navegação.

Quando nenhum marcador existe, não é possível reconstruir a paginação original sem uma informação externa da edição. Nesse caso, a aplicação deve oferecer paginação refluível calculada pela área de leitura, deixando claro que não é a página editorial original.

## Problema de preservar o texto

Não devemos inserir números, quebras ou rótulos no texto enviado ao TTS. A solução deve manter duas representações:

1. `cleanText`: texto sem marcadores, usado pela normalização, segmentação e síntese.
2. `pages`: estrutura de apresentação contendo trechos e `label`/número original, usada somente pelo leitor.

## Implementação recomendada

1. Criar `EpubPage` com `index`, `label`, `text`, `sourceChapterIndex` e posição inicial/final no capítulo.
2. Extrair marcadores de página do XHTML antes da sanitização, reconhecendo `epub:type`, `role`, `id`, `title` e classes sem depender de um único gerador de EPUB.
3. Alterar `EpubChapter` para expor `pages`, mantendo `cleanText` compatível com o pipeline atual.
4. Persistir também `pageIndex` junto com capítulo e frase.
5. Criar um `ReaderPageView` com navegação anterior/próxima, indicador `página atual / total` e seleção de frase dentro da página.
6. Para capítulos sem marcadores, usar modo `reflowable` separado, sem chamar o resultado de página original.
7. Adicionar fixtures com EPUB que tenha `pagebreak`, EPUB sem paginação e marcadores em arquivos XHTML separados.

## Decisão de produto

O leitor deve priorizar a paginação editorial quando ela estiver presente. Sem marcadores, deve continuar funcionando em modo refluível, sem fabricar uma falsa correspondência com a edição impressa.
