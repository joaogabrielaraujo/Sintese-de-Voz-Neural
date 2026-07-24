# Contexto e Decisões de Arquitetura - Fase 3: Fatiador de Sentenças (Sentence Segmenter)

## Objetivos da Fase
Desenvolver o módulo puramente funcional `lib/core/segmenter/` em Dart/Flutter para fatiar textos contínuos (extraídos de capítulos de livros EPUB) em sentenças sintaticamente coerentes, prontas para serem normalizadas (Fase 2) e sintetizadas incrementalmente (Fase 1).

---

## Decisões de Arquitetura e Design

### 1. Requisitos de Fatiamento (Sentence Chunking)
- **Delimitadores Principais**: `.`, `!`, `?`, `...` (reticências), e quebras duplas de parágrafo `\n\n`.
- **Proteção de Abreviações**: Não dividir em pontos que pertencem a abreviações conhecidas (`Dr.`, `Dra.`, `Prof.`, `pág.`, `Sr.`, `Sra.`, `etc.`, `vol.`, `art.`) ou iniciais de nomes (`J. K. Rowling`).
- **Sentenças de Diálogo**: Manter citações e aspas (`"..."`, `«...»`, `— ...`) unificadas com suas sentenças de fala.
- **Divisão Suave por Estouro de Tamanho (Soft Split)**: Se uma sentença ultrapassar o tamanho máximo recomendado (ex: > 180 caracteres), executar uma sub-divisão suave em pontuações secundárias (vírgulas `,`, pontos e vírgulas `;`, travessões `—`) para garantir latência baixa na inferência neural.

### 2. Estrutura de Saída (`TextSentence`)
A saída deve ser uma coleção imutável de objetos `TextSentence`:
- `index`: Índice sequencial da sentença no capítulo.
- `text`: O texto da sentença limpo.
- `isParagraphEnd`: Booleano indicando se a sentença encerra um parágrafo (essencial para renderização na UI móvel na Fase 8).

### 3. Cobertura de Testes Unitários
- Testar textos de artigos acadêmicos e parágrafos de livros com diálogos, reticências, abreviações intercaladas e frases extremamente longas.
