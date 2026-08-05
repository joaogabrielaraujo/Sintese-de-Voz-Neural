# Roadmap Granular do Projeto de TCC (Focado em MÃ³dulos Pequenos & Primeiro MVP)

Este roadmap foi reestruturado de forma **altamente modular e incremental**. Cada fase constrÃ³i uma pequena biblioteca/mÃ³dulo isolado com testes unitÃ¡rios/de integraÃ§Ã£o, culminando em um **Primeiro MVP funcional** e expansÃµes de resiliÃªncia e expressividade inspiradas na arquitetura do **VoxSherpa-TTS**.

---

## ðŸŽ¯ MILESTONE 1: PRIMEIRO MVP DE DEMONSTRAÃ‡ÃƒO (Para o Orientador)

### Phase 1: Motor de InferÃªncia Neural Core (PoC ONNX)

- **Foco**: Carregar a engine de inferÃªncia (Sherpa-onnx / Piper) em ambiente Flutter isolado, baixar o modelo VITS em PortuguÃªs (`pt_BR`) e sintetizar frases estÃ¡ticas em Ã¡udio WAV.
- **Testes**: Teste unitÃ¡rio de inferÃªncia, validaÃ§Ã£o do Ã¡udio WAV e cÃ¡lculo do Real-Time Factor (RTF) baseline.
- **Status**: ConcluÃ­do

### Phase 2: MÃ³dulo PLN de NormalizaÃ§Ã£o de Texto (TTS-Norm)

- **Foco**: Criar mÃ³dulo puramente funcional para conversÃ£o de numerais, ordinais, siglas, datas e sÃ­mbolos para extensÃ£o em PT-BR.
- **Testes**: Bateria de testes unitÃ¡rios automatizados cobrindo dezenas de casos de borda (ex: "R$ 150,00", "2026", "UEFS", "1Âº").
- **Status**: ConcluÃ­do

### Phase 3: Fatiador de SentenÃ§as (Sentence Segmenter)

- **Foco**: Criar algoritmo para divisÃ£o de textos longos em sentenÃ§as coerentes respeitando pontuaÃ§Ã£o, abreviaÃ§Ãµes e parÃ¡grafos.
- **Testes**: Testes unitÃ¡rios com textos de livros e artigos.
- **Status**: ConcluÃ­do

### Phase 4: Leitor & ExtraÃ§Ã£o de Texto EPUB (Parser XHTML/HTML)

- **Foco**: MÃ³dulo para abrir arquivos `.epub`, descompactar e extrair o texto estruturado por capÃ­tulos, removendo tags sem alterar o fluxo.
- **Testes**: Teste de integraÃ§Ã£o abrindo um arquivo `.epub` real e extraindo o texto limpo do CapÃ­tulo 1.
- **Status**: ConcluÃ­do

### ðŸŒŸ Phase 5: PRIMEIRO MVP (DemonstraÃ§Ã£o Funcional para o Orientador)

- **Foco**: Integrar os 4 mÃ³dulos anteriores em um pipeline funcional ponta-a-ponta (Abrir EPUB -> Extrair CapÃ­tulo -> Fatiar -> Normalizar PLN -> Sintetizar ONNX -> Reproduzir Ãudio com RelatÃ³rio de RTF).
- **EntregÃ¡vel**: AplicaÃ§Ã£o funcional de demonstraÃ§Ã£o (CLI/Interface simples) gerando Ã¡udio neural offline a partir de um EPUB real com relatÃ³rio de mÃ©tricas.
- **Status**: ConcluÃ­do

---

## âš¡ MILESTONE 2: PLAYER DE ÃUDIO, CONCORRÃŠNCIA & STREAMING MÃ“VEL

### Phase 6: Player de Ãudio Neural & AvaliaÃ§Ã£o Auditiva da Voz

- **Foco**: Integrar a camada de reproduÃ§Ã£o de Ã¡udio (`audioplayers` / `just_audio`), permitindo tocar o Ã¡udio sintetizado diretamente no dispositivo com controles (Play, Pause, Progress Bar) para validaÃ§Ã£o imediata da qualidade da voz pelo usuÃ¡rio/orientador.
- **Testes**: Teste de reproduÃ§Ã£o em hardware real, verificaÃ§Ã£o de latÃªncia de inicializaÃ§Ã£o e avaliaÃ§Ã£o perceptual da voz (MOS).
- **Status**: ConcluÃ­do

### Phase 7: Fila Concorrente AssÃ­ncrona & Buffer Circular (FIFO)

- **Foco**: Estrutura de dados Produtor-Consumidor assÃ­ncrona para gerenciar filas de sentenÃ§as e buffers de Ã¡udio em paralelo, garantindo reproduÃ§Ã£o fluida e sem pausas entre sentenÃ§as durante leituras longas.
- **Testes**: Testes de estresse de concorrÃªncia e gerenciamento de capacidade da fila.
- **Status**: ConcluÃ­do

### Phase 8: Gerenciador de MemÃ³ria & Thread de Purge (PrevenÃ§Ã£o OOM)

- **Foco**: Thread dedicada para descarte automÃ¡tico de buffers de Ã¡udio e sentenÃ§as jÃ¡ processadas, mantendo o consumo de RAM constante durante a leitura de livros inteiros.
- **Testes**: Teste de carga com capÃ­tulos de 10.000+ palavras verificando estabilidade da RAM.
- **Status**: ConcluÃ­do

---

## ðŸš€ MILESTONE 3: ARQUITETURA AVANÃ‡ADA, RESILIÃŠNCIA & INSPIRAÃ‡ÃƒO VOXSHERPA-TTS

### Phase 9.1: Arquitetura de ResiliÃªncia & Failover Multi-Motor TTS

- **Foco**: Orquestrador `CompositeTTSEngine` e `TTSEngineFactory` para comutaÃ§Ã£o dinÃ¢mica e transparente entre motores (Sherpa-ONNX C++, VITS ONNX Local e FlutterTTS SAPI5), com seletor interativo na UI.
- **Status**: ConcluÃ­do / Em Ajustes

### Phase 10: Processador AvanÃ§ado de Pausas, Expressividade & Tags de EmoÃ§Ã£o (VoxSherpa `AudioEmotionHelper`)

- **Foco**: Algoritmo de injeÃ§Ã£o de silÃªncios dinÃ¢micos com jitter suave por pontuaÃ§Ã£o (vÃ­rgula=140ms, ponto=280ms, reticÃªncias=380ms) e escalonamento por velocidade.
- **Testes**: Testes unitÃ¡rios de injeÃ§Ã£o de silÃªncio PCM e modulaÃ§Ã£o de perfil de Ã¡udio.
- **Status**: ConcluÃ­do

### Phase 11: ImportaÃ§Ã£o de PDF/TXT & Auto-DetecÃ§Ã£o de Modelos ONNX (VoxSherpa `TextImportHelper` & `VoiceEngine`)

- **Foco**: ExpansÃ£o do leitor para documentos PDF e TXT, alÃ©m de auto-detecÃ§Ã£o de taxa de amostragem (16k, 22.05k, 24k) e contagem de tokens do modelo ONNX.
- **Status**: ConcluÃ­do

### Phase 12: Plugin Nativo Android System-Wide TTS Service (VoxSherpa `VoxSherpaTtsService`)

- **Foco**: ExposiÃ§Ã£o da engine neural como motor TTS padrÃ£o do sistema Android (`TextToSpeechService`), permitindo que outros apps utilizem a voz local.
- **Status**: ConcluÃ­do

---

## ðŸ“Š MILESTONE 4: TELEMETRIA, AVALIAÃ‡ÃƒO QUANTITATIVA & DEFESA DO TCC

### Phase 13: SeleÃ§Ã£o de Arquivos Android & ImportaÃ§Ã£o Real de EPUB

- **Goal**: Permitir que a pessoa selecione um arquivo `.epub` pelo seletor nativo do Android e leia seu conteÃºdo real na aplicaÃ§Ã£o.
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
- **Plans:** 10 plans

Plans:
**Executado — identidades históricas preservadas**

- [x] 14-PLAN.md — Base estrutural responsiva (14-01)
- [x] 14-02-PLAN.md — Identidade EPUB e persistência transacional recuperável (`5fc8bb0`)
- [x] 14-03-PLAN.md — Cancelamento, ownership e handoff seguro de streaming (`cf5acc7`; `14-03-SUMMARY.md` completo)

**Wave 1**

- [x] 14-04-PLAN.md — Tracer de fontes locais, temas e preferência persistida

**Wave 2**

- [x] 14-05-PLAN.md — Biblioteca/importação editorial com progresso durável

**Wave 3**

- [x] 14-06-PLAN.md — Telemetria real metadata-only, fila e memória

**Wave 4**

- [x] 14-07-PLAN.md — Leitor contínuo, auto-scroll, player persistente e painel técnico

**Wave 5**

- [x] 14-08-PLAN.md — Atalhos, foco e acessibilidade na matriz responsiva

**Wave 6**

- [x] 14-09-PLAN.md — Goldens determinísticos light/dark com Windows/renderer declarado como autoridade

**Wave 7**

- [x] 14-10-PLAN.md — UAT nativo Android/Windows e aprovação visual
- **Status**: Concluído

### Phase 15: Suite de Testes de Carga, Telemetria & AvaliaÃ§Ã£o Quantitativa

- **Foco**: ExecuÃ§Ã£o de bateria de testes com livros de diferentes tamanhos (curto, mÃ©dio, longo) no dispositivo, gerando tabelas e grÃ¡ficos estatÃ­sticos de RTF, RAM (MB) e CPU.
- **Testes**: GeraÃ§Ã£o automatizada de dados para a seÃ§Ã£o de resultados da monografia.
- **Status**: Pendente

### Phase 16: RedaÃ§Ã£o da Monografia Final e Slides da Banca

- **Foco**: CompilaÃ§Ã£o de todos os dados, fundamentaÃ§Ã£o teÃ³rica, diagramas de arquitetura e resultados no documento do TCC.
- **Status**: Pendente
