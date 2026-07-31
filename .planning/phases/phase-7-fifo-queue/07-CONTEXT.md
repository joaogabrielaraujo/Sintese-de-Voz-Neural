# Contexto & Decisões de Arquitetura - Fase 7: Fila Concorrente Assíncrona & Buffer Circular (FIFO)

## 🎯 Objetivo da Fase 7
Implementar a estrutura de dados Produtor-Consumidor assíncrona (`CircularAudioBuffer` / `SentenceAudioQueue`) em `lib/core/queue/` para gerenciar o fluxo concorrente entre a inferência neural ONNX e a reprodução de áudio.

---

## 📋 Decisões de Arquitetura

### 1. Padrão Produtor-Consumidor (Producer-Consumer Pattern)
- **Produtor**: O `PipelineOrchestrator` fatia e sintetiza as sentenças do livro em background, colocando cada `SentenceAudioItem` (sentença + áudio PCM) na fila.
- **Consumidor**: O `AudioPlayerService` / Player UI desempilha e toca sequencialmente os itens da fila.

### 2. Time-To-First-Audio (TTFA < 300ms)
- Em leituras de livros longos, a reprodução deve iniciar **imediatamente** assim que a 1ª sentença for sintetizada, enquanto o resto do capítulo continua sendo sintetizado assincronamente em segundo plano.

### 3. Gerenciamento de Capacidade da Fila (Backpressure)
- A fila terá uma capacidade máxima configurável (ex: limite de 5 sentenças ou 30 segundos de áudio em memória RAM).
- Quando a fila atingir a capacidade máxima, o Produtor entra em *pause/await* até o Consumidor liberar espaço, evitando o consumo descontrolado de memória RAM.

---

## ⏩ Entregáveis da Fase 7
1. `07-01-PLAN.md`: Estrutura de dados `CircularAudioBuffer` e `SentenceAudioItem` com semáforo/backpressure async.
2. `07-02-PLAN.md`: Orquestração em Streaming no `PipelineOrchestrator`, integração no Player UI e bateria de testes de concorrência.
