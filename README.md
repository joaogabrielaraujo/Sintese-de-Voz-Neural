# 🎙️ Síntese de Voz Neural Offline em Dispositivos Móveis: Arquitetura e Implementação de um Leitor de EPUBs Baseado em Edge Computing

> **Trabalho de Conclusão de Curso (TCC)**  
> **Aluno**: João Gabriel Araújo Almeida (Matrícula: 22111215)  
> **Orientador**: Prof. Matheus Giovanni  
> **Instituição**: Colegiado do Curso de Engenharia de Computação — Universidade Estadual de Feira de Santana (UEFS)  
> **Framework & Linguagem**: Flutter | Dart (>=3.0.0)  
> **Palavras-chave**: Edge Computing, Text-to-Speech (TTS), VITS, ONNX Runtime, Sherpa-ONNX, PLN em PT-BR, EPUB Parsing.

---

## 📌 1. Visão Geral e Desafio Tecnológico

O objetivo deste projeto é projetar e implementar um leitor de livros digitais (`.epub`) capaz de realizar **síntese de voz neural 100% offline em dispositivos móveis** (Edge Computing).

### 🎯 O Desafio Tecnológico
Executar modelos de Deep Learning baseados em arquiteturas neurais avançadas (como **VITS / ONNX**) em smartphones (Android/iOS) impõe severas restrições de **memória RAM**, **processamento de CPU** e **bateria**. Além disso, a leitura contínua de capítulos longos sem tratamento adequado pode causar vazamentos de memória e travamentos na aplicação (*Out-Of-Memory - OOM*).

### 💡 A Solução Proposta
Uma arquitetura desacoplada em 5 módulos puramente funcionais que segmenta capítulos em pequenas frases sintaticamente coerentes, aplica normalização por extenso de elementos da língua portuguesa (moedas, datas, numerais e siglas) e envia o fluxo incrementalmente para o motor de inferência neural local, garantindo um **Real-Time Factor ($\text{RTF} < 1.0$)**.

---

## 🏗️ 2. Arquitetura da Pipeline de Dados (Fases 1 a 5)

A pipeline completa do **Primeiro MVP (Milestone 1)** foi organizada sob o diretório `lib/core/`:

```
[ Arquivo .EPUB / Capítulo XHTML ]
                │
                ▼
┌──────────────────────────────────────────────────────────┐
│  FASE 4: EPUB Parser & HTML Sanitizer                     │
│  (lib/core/epub/)                                        │
│  • Descompactação ZIP & Parsing do container.xml          │
│  • Resolução da ordem de leitura na <spine> do OPF       │
│  • Remoção puramente funcional de tags XHTML/HTML        │
└──────────────────────────────────────────────────────────┘
                │
                ▼ (Capítulo com Texto Limpo por Parágrafos)
┌──────────────────────────────────────────────────────────┐
│  FASE 3: Fatiador de Sentenças (Sentence Segmenter)       │
│  (lib/core/segmenter/)                                   │
│  • Fragmentação por pontuação (. ! ? ...)                │
│  • Proteção contra quebra em abreviações (Dr., Prof., pág)│
│  • Soft-split em frases longas (> 180 caracteres)        │
└──────────────────────────────────────────────────────────┘
                │
                ▼ (Lista de Objetos TextSentence)
┌──────────────────────────────────────────────────────────┐
│  FASE 2: Módulo PLN de Normalização (TTS-Norm)           │
│  (lib/core/nlp/)                                         │
│  • Extenso de Cardinais (0-999M) e Ordinais (1º-999º)     │
│  • Conversão de Moedas (R$ 150,00 -> cento e cinquenta)  │
│  • Conversão de Datas (24/07/2026) e Horários (14:30)     │
│  • Expansão de Siglas (UEFS -> U E F S) e Símbolos (%)   │
└──────────────────────────────────────────────────────────┘
                │
                ▼ (Frases Normalizadas por Extenso)
┌──────────────────────────────────────────────────────────┐
│  FASE 1: Engine de Inferência Neural ONNX Core           │
│  (lib/core/engine/)                                      │
│  • Carregamento imutável do modelo VITS PT-BR (ONNX)      │
│  • Reutilização de sessão e geração de amostras PCM      │
└──────────────────────────────────────────────────────────┘
                │
                ▼ (Amostras PCM Float32)
┌──────────────────────────────────────────────────────────┐
│  Serializador WAV RIFF & Telemetria de Desempenho        │
│  (lib/core/audio/ e lib/core/metrics/)                   │
│  • ByteData PCM Int16 com cabeçalho RIFF de 44 bytes     │
│  • Cálculo do Real-Time Factor (RTF = t_inferencia / t_audio)│
└──────────────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────┐
│  FASE 5: Fachada Orquestradora & Aplicativo Flutter MVP  │
│  (lib/core/pipeline/ & lib/main.dart)                     │
│  • PipelineOrchestrator: Execução ponta-a-ponta         │
│  • Interface Móvel com Sincronização UI e Player         │
│  • Gerador do Relatório de Desempenho do TCC             │
└──────────────────────────────────────────────────────────┘
```

---

## 🔍 3. Detalhamento Exaustivo dos Componentes Principais

### ⚡ 3.1. Engine de Inferência Neural Core (`lib/core/engine/`)
- **`ITTSEngine`**: Contrato abstrato que define as operações básicas da engine (`initialize`, `synthesize`, `synthesizeWithMetrics`, `dispose`).
- **`SherpaOnnxEngine`**: Wrapper que integra o modelo neural VITS em Português do Brasil (`pt_BR-faber-medium.onnx`). O modelo acústico gera amostras de áudio na taxa de amostragem de `22050 Hz`.
- **`MockTTSEngine`**: Motor de testes determinístico de ultra-alta velocidade utilizado para bateria de testes unitários automatizados e CI/CD sem necessidade de carregar o arquivo binário `.onnx` de 60MB.

```dart
// Exemplo de Invocação da Engine com Telemetria Integrada
final engine = SherpaOnnxEngine(config: TTSConfig.defaultPtBr());
await engine.initialize();

final result = await engine.synthesizeWithMetrics("Texto normalizado por extenso.");
print("Áudio Duração: ${result.audio.durationInSeconds} s");
print("RTF: ${result.metrics.rtf}");
```

---

### 🔊 3.2. Serializador de Áudio RIFF/WAV (`lib/core/audio/wav_writer.dart`)
Gera arquivos `.wav` sem utilizar bibliotecas externas pesadas, operando diretamente sobre o buffer binário em memória (`ByteData`).

- **Duração do Áudio**:
  $$\text{Duração (s)} = \frac{\text{Quantidade de Amostras}}{\text{Taxa de Amostragem (Hz)} \times \text{Canais}}$$
- **Construção do Cabeçalho RIFF de 44 Bytes**:
  - `0-3`: `"RIFF"`
  - `4-7`: Tamanho do arquivo menos 8 bytes
  - `8-11`: `"WAVE"`
  - `12-15`: `"fmt "` (Sub-chunk 1)
  - `20-21`: `1` (Formato PCM sem compressão)
  - `22-23`: `1` (Mono)
  - `24-27`: `22050` Hz
  - `36-39`: `"data"` (Sub-chunk 2)
  - `44+`: Amostras PCM 16-bit `clamp(-1.0, 1.0) * 32767`

---

### 📊 3.3. Telemetria de Desempenho e Métrica RTF (`lib/core/metrics/rtf_calculator.dart`)
O cálculo do **Fator de Tempo Real (Real-Time Factor - RTF)** determina se o dispositivo consegue sintetizar o áudio sem causar *pausas ou travamentos* durante a reprodução:

$$\text{RTF} = \frac{t_{\text{inferência}} \text{ (segundos)}}{t_{\text{áudio}} \text{ (segundos)}}$$

- **$\text{RTF} < 1.0$**: Inferência mais rápida que a reprodução do áudio (**APROVADO para Tempo Real**).
- **$\text{RTF} \ge 1.0$**: Sintetizador mais lento que o áudio (**REQUER OTIMIZAÇÃO**).

---

### 📝 3.4. Módulo PLN de Normalização de Texto (`lib/core/nlp/`)
Converte símbolos, marcas gramaticais e números em texto por extenso legível pelo sintetizador fonético:

1. **`number_to_words.dart`**: Converte inteiros de `0` a `999.999.999` e ordinais masculinos/femininos (`1º` -> `"primeiro"`, `2ª` -> `"segunda"`).
2. **`currency_normalizer.dart`**: Transforma valores em Reais (ex: `R$ 150,00` -> `"cento e cinquenta reais"`, `R$ 1,50` -> `"um real e cinquenta centavos"`).
3. **`date_time_normalizer.dart`**: Trata datas `DD/MM/AAAA` (ex: `24/07/2026` -> `"vinte e quatro de julho de dois mil e vinte e seis"`) e horários `HH:MM` (ex: `14:30` -> `"quatorze horas e trinta minutos"`).
4. **`abbreviation_normalizer.dart`**: Expande títulos (`Dr.` -> `"Doutor"`, `Prof.` -> `"Professor"`, `pág.` -> `"página"`), símbolos (`%` -> `"por cento"`, `&` -> `"e"`) e siglas (`UEFS` -> `"U E F S"`).
5. **`tts_normalizer.dart`**: Pipeline unificada que executa as etapas na ordem ótima e remove marcas HTML ou caracteres indesejados.

```dart
// Exemplo de Transmutação PLN:
final String raw = "Em 24/07/2026, o Dr. Matheus pagou R$ 150,00 na UEFS com 100% de desconto.";
final String clean = TTSNormalizer.normalize(raw);
// Resultado: "Em vinte e quatro de julho de dois mil e vinte e seis, o Doutor Matheus pagou cento e cinquenta reais na U E F S com cem por cento de desconto."
```

---

### ✂️ 3.5. Fatiador de Sentenças (`lib/core/segmenter/`)
Módulo responsável por dividir o fluxo contínuo dos capítulos em instâncias da classe imutável `TextSentence`.

- **Proteção contra Pontuação Falsa**: Utiliza um dicionário de abreviações para que a frase não seja quebrada incorretamente em marcas como `Dr.`, `Prof.` ou `pág.`.
- **Soft Split por Estouro de Caracteres**: Se uma frase longa ultrapassar `maxSentenceLength` (180 caracteres), realiza uma sub-divisão por vírgulas ou pontuações secundárias, garantindo alocação constante de RAM e latência reduzida no ONNX.
- **Sincronização UI**: Preserva a marcação `isParagraphEnd` para o destaque do texto no player móvel.

---

### 📖 3.6. Leitor & Parser de EPUB (`lib/core/epub/`)
Extrai e estrutura o conteúdo de arquivos digitais `.epub`:

- **`html_sanitizer.dart`**: Remove tags `<style>`, `<script>`, comentários e formatações preservando quebras de parágrafo `\n\n` e decodificando entidades HTML (`&nbsp;`, `&amp;`, `&lt;`, `&gt;`).
- **`epub_parser.dart`**: Lê a estrutura XML de `META-INF/container.xml`, descobre o local do arquivo manifesto `content.opf` e resolve a sequência exata dos capítulos através do nó `<spine>`.

---

### 👑 3.7. Fachada Orquestradora da Pipeline (`lib/core/pipeline/`)
- **`PipelineOrchestrator`**: Encapsula todo o fluxo de trabalho em um único método de fácil consumo:

```dart
final orchestrator = PipelineOrchestrator(engine: engine);
final PipelineResult result = await orchestrator.processChapter(
  book: epubBook,
  chapter: epubChapter,
);

print(result.generateAcademicReport());
```

---

## 🛠️ 4. Design Patterns e Princípios de Engenharia de Software

1. **Facade Pattern (Padrão Fachada)**: `PipelineOrchestrator` fornece uma interface simples para a complexa interação entre os 4 submódulos anteriores.
2. **Strategy / Abstract Factory Pattern**: `ITTSEngine` permite alternar dinamicamente entre motores neurais reais (`SherpaOnnxEngine`) e simulados (`MockTTSEngine`).
3. **Pure Functions & Immutability**: Todas as classes de modelo (`TTSConfig`, `AudioBuffer`, `TextSentence`, `EpubChapter`, `EpubBook`, `PipelineResult`) são marcadas com `@immutable` e os conversores PLN são funções puras sem efeito colateral.
4. **Single Responsibility Principle (SRP)**: Cada arquivo possui uma única função claramente delimitada.

---

## 📁 5. Estrutura Completa do Repositório

```
TCC/
├── assets/
│   └── models/
│       ├── README.md                 # Guia de instalação dos modelos ONNX
│       ├── tokens.txt                # Dicionário de tokens fonéticos em PT-BR (Incluído ✅)
│       └── pt_BR-faber-medium.onnx   # Modelo acústico ONNX (~60MB)
│
├── lib/
│   ├── main.dart                     # Aplicativo Flutter do Primeiro MVP com Player e UI
│   └── core/
│       ├── config/
│       │   └── tts_config.dart       # Hiperparâmetros da engine e caminhos
│       ├── audio/
│       │   └── wav_writer.dart       # Serializador de amostras PCM para WAV RIFF 44-byte
│       ├── metrics/
│       │   └── rtf_calculator.dart   # Telemetria de hardware e fórmula de RTF
│       ├── engine/
│       │   ├── tts_engine_interface.dart # Contrato abstrato ITTSEngine
│       │   ├── sherpa_onnx_engine.dart   # Engine de produção ONNX VITS
│       │   └── mock_tts_engine.dart      # Motor de teste determinístico
│       ├── nlp/
│       │   ├── number_to_words.dart      # Extenso de cardinais e ordinais
│       │   ├── currency_normalizer.dart  # Conversor de valores em Reais (R$)
│       │   ├── date_time_normalizer.dart # Conversor de datas e horários
│       │   ├── abbreviation_normalizer.dart # Expansor de siglas e abreviações
│       │   └── tts_normalizer.dart       # Pipeline orquestrador de PLN
│       ├── segmenter/
│       │   ├── sentence_model.dart   # Modelo imutável TextSentence
│       │   └── sentence_segmenter.dart # Algoritmo de fatiamento de sentenças
│       ├── epub/
│       │   ├── epub_model.dart       # Modelos imutáveis EpubBook e EpubChapter
│       │   ├── html_sanitizer.dart   # Sanitizador de tags XHTML/HTML
│       │   └── epub_parser.dart      # Parser de contêineres EPUB e Spine
│       └── pipeline/
│           ├── pipeline_result.dart  # Relatório acadêmico e métricas consolidadas
│           └── pipeline_orchestrator.dart # Fachada unificada da pipeline
│
├── test/                             # 11 Suítes completas de testes unitários e integração
│   └── core/
│       ├── config_test.dart
│       ├── wav_writer_test.dart
│       ├── rtf_calculator_test.dart
│       ├── tts_engine_test.dart
│       ├── nlp/
│       │   ├── number_to_words_test.dart
│       │   ├── currency_normalizer_test.dart
│       │   ├── date_time_normalizer_test.dart
│       │   ├── abbreviation_normalizer_test.dart
│       │   └── tts_normalizer_test.dart
│       ├── segmenter/
│       │   ├── sentence_model_test.dart
│       │   └── sentence_segmenter_test.dart
│       ├── epub/
│       │   ├── epub_model_test.dart
│       │   ├── html_sanitizer_test.dart
│       │   └── epub_parser_test.dart
│       └── pipeline/
│           └── pipeline_orchestrator_test.dart
│
├── .planning/                        # Gestão autônoma de fases (Metodologia GSD)
│   ├── PROJECT.md                    # Visão geral do TCC e responsabilidades
│   ├── REQUIREMENTS.md               # Requisitos Funcionais e Não-Funcionais (RF/RNF)
│   ├── ROADMAP.md                    # Histórico e acompanhamento de fases
│   ├── CODE_REVIEW.md                # Relatório detalhado do Code Review (Nota 9.8/10)
│   └── phases/                       # Planos executáveis e relatórios de verificação (Fases 1 a 5)
│
└── pubspec.yaml                      # Manifesto e dependências do projeto Flutter
```

---

## 🚀 6. Guia Prático para Execução e Testes

### 1. Obter Dependências do Projeto
```bash
flutter pub get
```

### 2. Executar a Suíte Completa de Testes Automatizados (100% Passando)
```bash
flutter test
```

### 3. Rodar a Aplicação Flutter de Demonstração (Primeiro MVP)
```bash
flutter run
```

---

## 📊 7. Exemplo do Relatório Acadêmico Gerado pelo MVP

```text
=====================================================================
🎓 RELATÓRIO DE DESEMPENHO DO PRIMEIRO MVP - TCC SÍNTESE NEURAL (UEFS)
=====================================================================
• Livro Processado     : Síntese de Voz Neural em Edge Computing
• Capítulo             : Capítulo 1: Fundamentação e Objetivos
• Total de Sentenças   : 2
• Total de Palavras    : 38
---------------------------------------------------------------------
• Tempo Total CPU/ONNX : 42.50 ms (0.043 s)
• Duração do Áudio WAV : 4.12 s
• Real-Time Factor (RTF): 0.0103
---------------------------------------------------------------------
📌 STATUS DO REQUISITO RNF-02 (Tempo Real): APROVADO (RTF < 1.0)
=====================================================================
```

---

## 🎓 Autor e Licença

- **Aluno**: João Gabriel Araújo Almeida (Engenharia de Computação — UEFS)
- **Orientador**: Prof. Matheus Giovanni
- **Finalidade**: Monografia e Trabalho de Conclusão de Curso (TCC).
