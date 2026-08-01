# Roadmap Granular do Projeto de TCC (Focado em Módulos Pequenos & Primeiro MVP)

Este roadmap foi reestruturado de forma **altamente modular e incremental**. Cada fase constrói uma pequena biblioteca/módulo isolado com testes unitários/de integração, culminando em um **Primeiro MVP funcional** e expansões de resiliência e expressividade inspiradas na arquitetura do **VoxSherpa-TTS**.

---

## 🎯 MILESTONE 1: PRIMEIRO MVP DE DEMONSTRAÇÃO (Para o Orientador)

### Phase 1: Motor de Inferência Neural Core (PoC ONNX)

- **Foco**: Carregar a engine de inferência (Sherpa-onnx / Piper) em ambiente Flutter isolado, baixar o modelo VITS em Português (`pt_BR`) e sintetizar frases estáticas em áudio WAV.
- **Testes**: Teste unitário de inferência, validação do áudio WAV e cálculo do Real-Time Factor (RTF) baseline.
- **Status**: Concluído

### Phase 2: Módulo PLN de Normalização de Texto (TTS-Norm)

- **Foco**: Criar módulo puramente funcional para conversão de numerais, ordinais, siglas, datas e símbolos para extensão em PT-BR.
- **Testes**: Bateria de testes unitários automatizados cobrindo dezenas de casos de borda (ex: "R$ 150,00", "2026", "UEFS", "1º").
- **Status**: Concluído

### Phase 3: Fatiador de Sentenças (Sentence Segmenter)

- **Foco**: Criar algoritmo para divisão de textos longos em sentenças coerentes respeitando pontuação, abreviações e parágrafos.
- **Testes**: Testes unitários com textos de livros e artigos.
- **Status**: Concluído

### Phase 4: Leitor & Extração de Texto EPUB (Parser XHTML/HTML)

- **Foco**: Módulo para abrir arquivos `.epub`, descompactar e extrair o texto estruturado por capítulos, removendo tags sem alterar o fluxo.
- **Testes**: Teste de integração abrindo um arquivo `.epub` real e extraindo o texto limpo do Capítulo 1.
- **Status**: Concluído

### 🌟 Phase 5: PRIMEIRO MVP (Demonstração Funcional para o Orientador)

- **Foco**: Integrar os 4 módulos anteriores em um pipeline funcional ponta-a-ponta (Abrir EPUB -> Extrair Capítulo -> Fatiar -> Normalizar PLN -> Sintetizar ONNX -> Reproduzir Áudio com Relatório de RTF).
- **Entregável**: Aplicação funcional de demonstração (CLI/Interface simples) gerando áudio neural offline a partir de um EPUB real com relatório de métricas.
- **Status**: Concluído

---

## ⚡ MILESTONE 2: PLAYER DE ÁUDIO, CONCORRÊNCIA & STREAMING MÓVEL

### Phase 6: Player de Áudio Neural & Avaliação Auditiva da Voz

- **Foco**: Integrar a camada de reprodução de áudio (`audioplayers` / `just_audio`), permitindo tocar o áudio sintetizado diretamente no dispositivo com controles (Play, Pause, Progress Bar) para validação imediata da qualidade da voz pelo usuário/orientador.
- **Testes**: Teste de reprodução em hardware real, verificação de latência de inicialização e avaliação perceptual da voz (MOS).
- **Status**: Concluído

### Phase 7: Fila Concorrente Assíncrona & Buffer Circular (FIFO)

- **Foco**: Estrutura de dados Produtor-Consumidor assíncrona para gerenciar filas de sentenças e buffers de áudio em paralelo, garantindo reprodução fluida e sem pausas entre sentenças durante leituras longas.
- **Testes**: Testes de estresse de concorrência e gerenciamento de capacidade da fila.
- **Status**: Concluído

### Phase 8: Gerenciador de Memória & Thread de Purge (Prevenção OOM)

- **Foco**: Thread dedicada para descarte automático de buffers de áudio e sentenças já processadas, mantendo o consumo de RAM constante durante a leitura de livros inteiros.
- **Testes**: Teste de carga com capítulos de 10.000+ palavras verificando estabilidade da RAM.
- **Status**: Concluído

---

## 🚀 MILESTONE 3: ARQUITETURA AVANÇADA, RESILIÊNCIA & INSPIRAÇÃO VOXSHERPA-TTS

### Phase 9.1: Arquitetura de Resiliência & Failover Multi-Motor TTS

- **Foco**: Orquestrador `CompositeTTSEngine` e `TTSEngineFactory` para comutação dinâmica e transparente entre motores (Sherpa-ONNX C++, VITS ONNX Local e FlutterTTS SAPI5), com seletor interativo na UI.
- **Status**: Concluído / Em Ajustes

### Phase 10: Processador Avançado de Pausas, Expressividade & Tags de Emoção (VoxSherpa `AudioEmotionHelper`)

- **Foco**: Algoritmo de injeção de silêncios dinâmicos com jitter suave por pontuação (vírgula=140ms, ponto=280ms, reticências=380ms) e escalonamento por velocidade.
- **Testes**: Testes unitários de injeção de silêncio PCM e modulação de perfil de áudio.
- **Status**: Concluído

### Phase 11: Importação de PDF/TXT & Auto-Detecção de Modelos ONNX (VoxSherpa `TextImportHelper` & `VoiceEngine`)

- **Foco**: Expansão do leitor para documentos PDF e TXT, além de auto-detecção de taxa de amostragem (16k, 22.05k, 24k) e contagem de tokens do modelo ONNX.
- **Status**: Concluído

### Phase 12: Plugin Nativo Android System-Wide TTS Service (VoxSherpa `VoxSherpaTtsService`)

- **Foco**: Exposição da engine neural como motor TTS padrão do sistema Android (`TextToSpeechService`), permitindo que outros apps utilizem a voz local.
- **Status**: Concluído

---

## 📊 MILESTONE 4: TELEMETRIA, AVALIAÇÃO QUANTITATIVA & DEFESA DO TCC

### Phase 13: Seleção de Arquivos Android & Importação Real de EPUB

- **Goal**: Permitir que a pessoa selecione um arquivo `.epub` pelo seletor nativo do Android e leia seu conteúdo real na aplicação.
- **Depends on**: Phase 12
- **Requirements**: RF-01, RNF-04
- **Success Criteria** (what must be TRUE):
  1. User can open the Android file picker and select an EPUB from device storage.
  2. The application rejects unsupported extensions and handles cancellation or invalid files gracefully.
  3. The selected EPUB is parsed from real file bytes into book metadata and ordered chapters.
  4. User can choose an imported chapter and start the existing reading pipeline.
- **Plans**: TBD

### Phase 14: Redesign da UI e Leitor Responsivo Android/Windows

- **Foco**: Aplicar a linguagem visual do `design_mockup.html` ao aplicativo Flutter, com biblioteca, leitor sincronizado e player responsivo.
- **Plataformas**: Layout mobile para Android e layout adaptado para mouse, teclado e janelas largas no Windows.
- **Critério**: A nova UI preserva o pipeline offline, as métricas RTF/MOS/memória e os fluxos de importação e leitura existentes.
- **Plans:** 7 plans

Plans:
- [x] 14-PLAN.md — Redesign editorial responsivo executado
- [ ] 14-02-PLAN.md — Identidade EPUB e persistência transacional recuperável
- [ ] 14-03-PLAN.md — Cancelamento e substituição segura de streaming
- [ ] 14-04-PLAN.md — Progresso durável e estados coerentes de biblioteca/importação
- [ ] 14-05-PLAN.md — Tracer de telemetria RTF a partir do streaming real
- [ ] 14-06-PLAN.md — MOS, relatório, fila e memória alcançáveis
- [ ] 14-07-PLAN.md — Gestos estáveis e cobertura responsiva final
- **Status**: Em planejamento

### Phase 15: Suite de Testes de Carga, Telemetria & Avaliação Quantitativa

- **Foco**: Execução de bateria de testes com livros de diferentes tamanhos (curto, médio, longo) no dispositivo, gerando tabelas e gráficos estatísticos de RTF, RAM (MB) e CPU.
- **Testes**: Geração automatizada de dados para a seção de resultados da monografia.
- **Status**: Pendente

### Phase 16: Redação da Monografia Final e Slides da Banca

- **Foco**: Compilação de todos os dados, fundamentação teórica, diagramas de arquitetura e resultados no documento do TCC.
- **Status**: Pendente
