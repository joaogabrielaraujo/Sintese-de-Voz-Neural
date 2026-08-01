# Contexto & Decisões de Arquitetura - Fase 8: Gerenciador de Memória & Thread de Purge (Prevenção OOM)

## 🎯 Objetivo da Fase 8
Desenvolver o módulo de gerenciamento de memória `MemoryManager` em `lib/core/memory/` com política de purge automático (descarte de buffers de áudio PCM já reproduzidos). O objetivo é garantir consumo de memória RAM constante ($\mathcal{O}(1)$) durante a leitura de livros inteiros (10.000+ palavras), prevenindo vazamentos de memória e erros de *Out-Of-Memory (OOM)* no Edge Computing.

---

## 📋 Decisões de Arquitetura

### 1. Política de Purge Imediato (Post-Playback Purge)
- Assim que o `AudioPlayerService` encerra a reprodução de um `SentenceAudioItem`, o `MemoryManager` desaloca os dados de amostra PCM (`Float32List`) e libera a referência do item da memória.

### 2. Teto de Consumo de RAM (Memory Threshold)
- Limite máximo teto configurável de RAM para buffers de áudio (padrão: `maxMemoryMb = 50.0 MB`).
- Se a pegada de memória estimada ultrapassar o teto, o Produtor pausa a síntese até que itens antigos sejam descartados pelo Consumidor.

### 3. Módulo de Telemetria de RAM (`MemoryStats`)
- Fornece métricas em tempo real sobre a pegada de memória alocada (`currentAllocatedBytes`, `currentAllocatedMb`, `purgedItemsCount`, `freedBytes`).

---

## ⏩ Entregáveis da Fase 8
1. `08-01-PLAN.md`: Implementação do `MemoryManager` e `MemoryStats` com testes de desalocação.
2. `08-02-PLAN.md`: Teste de carga e estresse com livros longos (10.000+ palavras) validando a estabilidade da memória RAM.
