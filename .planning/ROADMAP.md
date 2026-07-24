# Roadmap Granular do Projeto de TCC (Focado em Módulos Pequenos & Primeiro MVP)

Este roadmap foi reestruturado de forma **altamente modular e incremental**. Cada fase constrói uma pequena biblioteca/módulo isolado com testes unitários/de integração, culminating em um **Primeiro MVP funcional** focado na demonstração ao orientador antes de avançar para a arquitetura móvel complexa.

---

## 🎯 MILESTONE 1: PRIMEIRO MVP DE DEMONSTRAÇÃO (Para o Orientador)

### Fase 1: Motor de Inferência Neural Core (PoC ONNX)
- **Foco**: Carregar a engine de inferência (Sherpa-onnx / Piper) em ambiente Flutter isolado, baixar o modelo VITS em Português (`pt_BR`) e sintetizar frases estáticas em áudio WAV.
- **Testes**: Teste unitário de inferência, validação do áudio WAV e cálculo do Real-Time Factor (RTF) baseline.
- **Status**: Concluído


### Fase 2: Módulo PLN de Normalização de Texto (TTS-Norm)
- **Foco**: Criar módulo puramente funcional para conversão de numerais, ordinais, siglas, datas e símbolos para extensão em PT-BR.
- **Testes**: Bateria de testes unitários automatizados cobrindo dezenas de casos de borda (ex: "R$ 150,00", "2026", "UEFS", "1º").
- **Status**: Concluído


### Fase 3: Fatiador de Sentenças (Sentence Segmenter)
- **Foco**: Criar algoritmo para divisão de textos longos em sentenças coerentes respeitando pontuação, abreviações e parágrafos.
- **Testes**: Testes unitários com textos de livros e artigos.
- **Status**: Concluído


### Fase 4: Leitor & Extração de Texto EPUB (Parser XHTML/HTML)
- **Foco**: Módulo para abrir arquivos `.epub`, descompactar e extrair o texto estruturado por capítulos, removendo tags sem alterar o fluxo.
- **Testes**: Teste de integração abrindo um arquivo `.epub` real e extraindo o texto limpo do Capítulo 1.
- **Status**: Concluído


### 🌟 Fase 5: PRIMEIRO MVP (Demonstração Funcional para o Orientador)
- **Foco**: Integrar os 4 módulos anteriores em um pipeline funcional ponta-a-ponta (Abrir EPUB -> Extrair Capítulo -> Fatiar -> Normalizar PLN -> Sintetizar ONNX -> Reproduzir Áudio com Relatório de RTF).
- **Entregável**: Aplicação funcional de demonstração (CLI/Interface simples) gerando áudio neural offline a partir de um EPUB real com relatório de métricas.
- **Status**: Concluído


---

## ⚡ MILESTONE 2: PLAYER DE ÁUDIO, CONCORRÊNCIA & STREAMING MÓVEL

### Fase 6: Player de Áudio Neural & Avaliação Auditiva da Voz
- **Foco**: Integrar a camada de reprodução de áudio (`audioplayers` / `just_audio`), permitindo tocar o áudio sintetizado diretamente no dispositivo com controles (Play, Pause, Progress Bar) para validação imediata da qualidade da voz pelo usuário/orientador.
- **Testes**: Teste de reprodução em hardware real, verificação de latência de inicialização e avaliação perceptual da voz (MOS).
- **Status**: Pendente

### Fase 7: Fila Concorrente Assíncrona & Buffer Circular (FIFO)
- **Foco**: Estrutura de dados Produtor-Consumidor assíncrona para gerenciar filas de sentenças e buffers de áudio em paralelo, garantindo reprodução fluida e sem pausas entre sentenças durante leituras longas.
- **Testes**: Testes de estresse de concorrência e gerenciamento de capacidade da fila.
- **Status**: Pendente

### Fase 8: Gerenciador de Memória & Thread de Purge (Prevenção OOM)
- **Foco**: Thread dedicada para descarte automático de buffers de áudio e sentenças já processadas, mantendo o consumo de RAM constante durante a leitura de livros inteiros.
- **Testes**: Teste de carga com capítulos de 10.000+ palavras verificando estabilidade da RAM.
- **Status**: Pendente

---

## 📊 MILESTONE 3: TELEMETRIA, AVALIAÇÃO QUANTITATIVA & DEFESA

### Fase 9: Módulo de Telemetria de Hardware (RTF, RAM e CPU)
- **Foco**: Sistema de logs e telemetria em tempo real para monitorar RTF por sentença, uso de RAM (MB) e pegada de CPU durante execuções longas.
- **Testes**: Testes de registro de estatísticas em arquivos CSV/JSON.
- **Status**: Pendente

### Fase 10: Suite de Testes de Carga & Avaliação Quantitativa
- **Foco**: Execução de bateria de testes com livros de diferentes tamanhos (curto, médio, longo) no dispositivo, gerando tabelas e gráficos estatísticos.
- **Testes**: Geração automatizada de dados para a seção de resultados do TCC.
- **Status**: Pendente

### Fase 11: Redação da Monografia Final e Slides da Banca
- **Foco**: Compilação de todos os dados, fundamentação teórica, diagramas de arquitetura e resultados no documento do TCC.
- **Status**: Pendente
