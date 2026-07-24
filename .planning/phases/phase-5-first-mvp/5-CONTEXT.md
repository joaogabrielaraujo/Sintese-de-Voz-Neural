# Contexto e Decisões de Arquitetura - Fase 5: PRIMEIRO MVP (Demonstração Funcional para o Orientador)

## Objetivos da Fase
Integrar os 4 módulos construídos nas fases anteriores (`core/epub`, `core/segmenter`, `core/nlp`, `core/engine`) em uma fachada única e consolidada (`PipelineOrchestrator`), fornecendo uma aplicação móvel funcional ponta-a-ponta em Flutter para demonstração ao orientador (Prof. Matheus Giovanni), capaz de:
1. Abrir um livro `.epub` real.
2. Extrair o texto limpo do Capítulo 1.
3. Fatiar o capítulo em sentenças sintáticas coerentes (`TextSentence`).
4. Normalizar todas as frases por extenso em Português (`pt_BR`).
5. Sintetizar áudio neural offline em lote/streaming.
6. Gerar um relatório consolidado de métricas (Duração Total do Áudio, Tempo Total de CPU/Inferência, e RTF Global da execução).

---

## Decisões de Arquitetura e Design

### 1. Fachada Orquestradora (`lib/core/pipeline/pipeline_orchestrator.dart`)
- **Padrão Facade**: O controlador `PipelineOrchestrator` esconde a complexidade interna da cadeia de execução.
- Expõe um método simples: `Future<PipelineResult> processEpubChapter(EpubChapter chapter)`.

### 2. Relatório de Desempenho para Apresentação Acadêmica (`PipelineResult`)
Objeto contendo:
- `bookTitle`: Título do livro.
- `chapterTitle`: Nome do capítulo processado.
- `totalSentences`: Quantidade de sentenças sintetizadas.
- `totalWords`: Quantidade de palavras.
- `totalAudioDuration`: Duração total do áudio em segundos.
- `totalInferenceTimeMs`: Latência acumulada de inferência em ms.
- `overallRtf`: Fator de Tempo Real global ($\text{RTF} = t_{\text{inferência}} / t_{\text{áudio}}$).
- `formattedSummary()`: Texto formatado para exportação de relatório no TCC.

### 3. Interface de Usuário (UI) Final do MVP
- Interface elegante em Material 3 Dark Theme.
- Controles de reprodução (Play, Pause, Reset), barra de progresso por sentença e exibição gráfica dos cartões de métricas.
