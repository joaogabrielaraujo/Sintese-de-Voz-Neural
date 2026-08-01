# CONTEXT: Fase 10 - Processador Avançado de Pausas & Ritmo Humano por Pontuação

## 🎯 Objetivo
Implementar em Dart um processador de ritmo de fala humana (`PunctuationPauseHelper`), fortemente inspirado no algoritmo do repositório **VoxSherpa-TTS**, injetando silêncios dinâmicos com jitter estocástico suave (±10%) e escalonamento proporcional à velocidade de leitura, garantindo que a síntese neural de livros e EPUBs possua pausas naturais e agradáveis.

---

## 🛠️ Decisões Arquiteturais Locked (Decididas pelo Usuário)

### 1. Injeção Dinâmica de Silêncios por Pontuação
- **Vírgula (`,`)**: ~140ms de silêncio PCM.
- **Exclamação (`!`)**: ~190ms de silêncio PCM.
- **Interrogação (`?`)**: ~230ms de silêncio PCM.
- **Ponto final (`.`)**: ~280ms de silêncio PCM.
- **Reticências (`...`)**: ~380ms de silêncio PCM.
- **Jitter Estocástico Suave (±10%)**: Variação aleatória determinística para evitar tom mecânico repetitivo.
- **Escalonamento pela Velocidade**: O tempo de pausa é ajustado inversamente pela velocidade de leitura (`silenceMs / speed`).
- **Controle pelo Usuário na UI**: Adição de um parâmetro/slider de intensidade de pausa nas configurações.

### 2. Escopo de Texto (Sem Tags de Emoção)
- Foco exclusivo no ritmo e pontuação humana. Tags entre colchetes como `[whisper]` ou `[sad]` serão higienizadas/ignoradas para manter a leitura do e-book limpa e fluida.

### 3. Integração na Pipeline Streaming
- O `PunctuationPauseHelper` atuará entre o `SentenceSegmenter` e o `CircularAudioBuffer`, injetando amostras PCM zeradas (16-bit) ajustadas para a taxa de amostragem ativa (16kHz, 22.05kHz, 24kHz).

---

## 📋 Critérios de Aceitação
- [ ] Classe `PunctuationPauseHelper` implementada em `lib/core/audio/punctuation_pause_helper.dart`.
- [ ] Suporte a taxas de amostragem dinâmicas (16kHz, 22.05kHz, 24kHz).
- [ ] Slider / Controle de intensidade de pausa integrado na UI.
- [ ] Bateria de testes unitários validando a duração dos buffers de silêncio gerados com jitter.
