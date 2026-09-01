# VozLume — Síntese de Voz Neural Offline em Dispositivos Móveis

## Leitor EPUB baseado em Edge Computing, Sherpa-ONNX, Piper VITS e Supertonic 3

Projeto de Trabalho de Conclusão de Curso (TCC) desenvolvido por **João Gabriel Araújo Almeida**, no curso de Engenharia de Computação da Universidade Estadual de Feira de Santana (UEFS), sob orientação de Ana Lúcia Lima Marreiros.

O **VozLume** é um aplicativo leitor de livros digitais (EPUB) focado em síntese de voz neural offline em Português Brasileiro (PT-BR). O software opera com baixa latência (Time-To-First-Audio < 300ms) e consumo de memória RAM controlado através de técnicas de *Edge Computing* em dispositivos Android e Windows.

---

## 1. Créditos e Agradecimentos a Projetos Open-Source

O desenvolvimento deste projeto foi possível graças a importantes iniciativas open-source de síntese de voz neural e processamento de áudio:

* **[Piper TTS](https://github.com/rhasspy/piper) (por Michael Hansen / Rhasspy)**:
  Projeto open-source de síntese de voz neural rápida e local focada em dispositivos de borda. O VozLume utiliza o modelo VITS PT-BR **Faber** (`pt_BR-faber-medium.onnx`), treinado sob a arquitetura VITS (Variational Inference with adversarial learning for end-to-end Text-to-Speech) integrada ao dicionário fonético `espeak-ng`.
* **[Supertonic 3](https://github.com/k2-fsa/sherpa-onnx)**:
  Arquitetura neural leve de síntese de voz multi-estágio otimizada para inferência inteira (`int8.onnx`), permitindo execuções extremamente rápidas com consumo de CPU mínimo em dispositivos móveis.
* **[Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx) (Next-gen Kaldi / por Dan Povey et al.)**:
  Engine de inferência neural nativa em C++ compilada para múltiplas plataformas. Atua como o motor de execução FFI (*Foreign Function Interface*) do VozLume, carregando os modelos ONNX diretamente em código nativo sem dependências de nuvem.
* **[Audioplayers](https://github.com/bluefireteam/audioplayers)**:
  Plugin Flutter para reprodução nativa de buffers de áudio PCM/WAV nos sistemas operacionais Android e Windows.

---

## 2. Visão Geral da Lógica do Sistema

O aplicativo adota uma arquitetura em pipeline desacoplada que trata a leitura de e-books como um **fluxo de áudio sob demanda (*streaming FIFO*)**. Em vez de sintetizar o livro ou capítulo inteiro de uma vez (o que causaria congelamentos e estouro de memória RAM), o sistema gera e reproduz o áudio **frase por frase**, mantendo uma pequena janela na memória.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        ETAPA 1: INGESTÃO EPUB                          │
│  • Importação de bytes do arquivo .epub (sem permissões invasivas)     │
│  • Validação ZIP e navegação em META-INF/container.xml                 │
│  • Parsing do manifesto OPF (metadata, manifest, spine)                │
│  • Extração de Capas (EPUB 3 cover-image / EPUB 2 meta cover)          │
│  • Fatiamento inteligente por âncoras #id (NAV/NCX) ou cabeçalhos <h1> │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    ETAPA 2: SEGMENTAÇÃO DE TEXTO                       │
│  • SentenceSegmenter: Divisão por pontuações de fim de frase           │
│  • Atribuição de Índices Absolutos para navegação e salto no texto     │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   ETAPA 3: NORMALIZAÇÃO (PLN PT-BR)                    │
│  • TTSNormalizer: Expansão de datas, moedas, ordinais e maiúsculas     │
│  • PhoneticNormalizer: Tratamento G2P com preservação de acentos PT-BR │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               ETAPA 4: INFERÊNCIA NEURAL FFI C++ (TTS)                 │
│  • CompositeTTSEngine (Failover Automático e Seleção de Motores)       │
│  • Execução C++ via Sherpa-ONNX na CPU do dispositivo                  │
│     ├── Piper Faber VITS (pt_BR-faber-medium.onnx)                     │
│     └── Supertonic 3 (int8.onnx multi-estágio)                         │
│  • Parâmetros prosódicos: lengthScale=1.12, noiseScale=0.85, W=0.95    │
└────────────────────────────────────────────────────────────────────────┘
                                    │ PCM Float32 (22050 Hz)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               ETAPA 5: GESTÃO DE MEMÓRIA & REPRODUÇÃO                  │
│  • CircularAudioBuffer: Fila FIFO com capacidade máxima de 5 itens     │
│  • Backpressure: Pausa a síntese se a fila estiver cheia               │
│  • Purge de RAM: MemoryManager zera e descarta o áudio após tocar      │
│  • AudioPlayerService: Converte PCM em RIFF/WAV e envia ao alto-falante│
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               ETAPA 6: INTERFACE & SINCRONIA VISUAL                    │
│  • Destaque em tempo real da frase ativa com o tema de cor escolhido   │
│  • Toque em qualquer trecho -> Seleção Pendente -> Salto Confirmado    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Explicação Detalhada do Passo a Passo da Lógica

Para entender como a leitura de um livro acontece dentro do projeto, o processo é dividido em 6 etapas sequenciais:

### Etapa 1: Ingestão e Fatiamento do EPUB
1. O usuário seleciona um arquivo `.epub` no dispositivo.
2. O `EpubBytesImporter` lê o conteúdo como um array de bytes (Uint8List), valida a estrutura comprimida ZIP e abre o arquivo `META-INF/container.xml` para encontrar o manifesto principal (`package.opf`).
3. O `EpubParser` lê a `spine` (ordem de leitura do livro) e os metadados. Ele busca a **capa do livro** (metadados EPUB 3 `properties="cover-image"` ou EPUB 2 `<meta name="cover">`) e a salva localmente para ser exibida no card da biblioteca.
4. **Fatiamento Inteligente**: Arquivos XHTML comerciais frequentemente contêm livros inteiros ou seções gigantescas. Para evitar travamentos, o parser verifica o sumário NCX/NAV e fatia o documento nos pontos exatos das âncoras de capítulo (`#id`). Na ausência de âncoras, ele fatia pelas tags de cabeçalho (`<h1>`, `<h2>`).

### Etapa 2: Segmentação de Sentenças e Indexação Absoluta
1. O texto limpo do capítulo fatiado é enviado ao `SentenceSegmenter`.
2. O texto é dividido em frases individuais utilizando pontuações de término (`.`, `!`, `?`, `;`, quebras de parágrafo).
3. Cada frase recebe um **índice absoluto sequencial** (ex: Frase 0, Frase 1, Frase 2...). Essa indexação é fundamental para que o leitor saiba exatamente qual trecho está sendo lido na tela e permita saltos diretos.

### Etapa 3: Normalização Linguística (PLN PT-BR)
Antes de enviar o texto ao modelo neural, ele passa por duas camadas de preparação em português brasileiro:
* `TTSNormalizer`: Converte elementos gráficos em palavras por extenso.
  * *Moedas*: `R$ 150,50` $\rightarrow$ `duzentos e cinquenta reais e cinquenta centavos`.
  * *Datas*: `24/07/2026` $\rightarrow$ `vinte e quatro de julho de dois mil e vinte e seis`.
  * *Numerais Romanos*: `Capítulo III` $\rightarrow$ `Capítulo três`.
  * *Siglas*: `UEFS` $\rightarrow$ `U E F S`.
* `PhoneticNormalizer`: Preserva acentuação e cedilha (`ação`, `órgão`, `sintese`) essenciais para a conversão de fonemas do `espeak-ng`, removendo apenas caracteres invisíveis de controle.

### Etapa 4: Inferência Neural via FFI C++ (Sherpa-ONNX)
1. A frase normalizada é enviada à `CompositeTTSEngine`.
2. O motor selecionado (Faber VITS ou Supertonic 3) aciona a biblioteca C++ `sherpa-onnx` nativa via FFI.
3. **Ajustes de Prosódia do Faber**:
   * `lengthScale = 1.12`: Estende a duração de cada fonema em **12%**, conferindo clareza e ritmo natural de leitura sem engolir sílabas.
   * `noiseScale = 0.85` e `noiseScaleW = 0.95`: Garante entonação rica e estabilidade temporal no previsor estocástico de duração.
4. A C++ gera um buffer de áudio em formato **PCM Float32 (22050 Hz)** na memória.

### Etapa 5: Streaming FIFO, Fila Circular e Gestão de RAM (Anti-OOM)
1. O áudio sintetizado é envelopado em um objeto `SentenceAudioItem` e inserido na `CircularAudioBuffer` (fila FIFO com capacidade de até 5 sentenças).
2. **Mecanismo de Backpressure**: Se a fila estiver cheia (5 frases prontas aguardando reprodução), o sintetizador pausa automaticamente a produção. Isso impede que a memória RAM do celular estoure (*Out Of Memory - OOM*).
3. O `AudioPlayerService` retira o primeiro item da fila, serializa o PCM Float32 em um buffer RIFF/WAV via `WavWriter` e envia para reprodução no alto-falante.
4. **Purge da Memória RAM**: Assim que o player termina de tocar a frase, o `MemoryManager` zera e descarta os dados da amostra Float32 imediatamente, mantendo o consumo de RAM plano abaixo de 50MB.

### Etapa 6: Interface Reativa, Destaque Visual e Seleção Confirmada
1. Durante a leitura, a frase atualmente em reprodução recebe destaque visual na tela com a cor da paleta selecionada (Padrão, Botânico, Carmim ou Marinha).
2. **Seleção Confirmada**: Se o usuário tocar em qualquer outra frase do texto, o app não interrompe o áudio imediatamente (evitando acidentes). Em vez disso, exibe um painel de *Seleção Pendente*. Ao clicar em *"Continuar da frase N"*, a fila atual é cancelada e o pipeline reinicia a síntese a partir do novo índice selecionado.

---

## 4. Sistema de Temas Editoriais de Cores

O aplicativo conta com **4 paletas de cores editoriais** desenvolvidas para conforto visual em diferentes ambientes de leitura:

| Paleta | Tom do Fundo (Claro / Escuro) | Característica e Leitura Editorial |
| :--- | :--- | :--- |
| **Padrão** | `#E7DFC6` / `#262A22` | Papel pergaminho clássico com destaque em tom azul editorial. |
| **Botânico** | `#E6E9DF` / `#1E2219` | Tom papel-erva suavizado com sinalização e grifo herbal em verde. |
| **Carmim** | `#EEE0E0` / `#241A1C` | Papel rosado elegante com destaques e sinalização em tom vinhoso. |
| **Marinha** | `#DDE2EC` / `#181C26` | Papel azulado sereno com detalhes em azul prússia e terracota. |

---

## 5. Estrutura de Código do Repositório

```text
lib/
├── main.dart                          # Ponto de entrada, auto-detecção de modelos e MaterialApp
├── core/
│   ├── audio/                         # AudioPlayerService (audioplayers) e WavWriter (PCM16)
│   ├── config/                        # TTSConfig (Faber VITS) e SupertonicConfig (Supertonic 3)
│   ├── document/                      # EpubParser, EpubBytesImporter, SavedBookRepository e HtmlSanitizer
│   ├── engine/                        # Interface ITTSEngine, SherpaOnnx, SupertonicOnnx e Composite
│   ├── memory/                        # CircularAudioBuffer, MemoryManager e SentenceAudioItem
│   ├── metrics/                       # PerformanceTracker e RtfCalculator (Real-Time Factor)
│   ├── pipeline/                      # PipelineOrchestrator (Segmentação -> PLN -> Síntese -> Fila)
│   └── text/                          # SentenceSegmenter, TTSNormalizer e PhoneticNormalizer
└── ui/
    ├── app_theme.dart                 # AppThemePalette, tokens de cor e AppThemeExtension
    ├── theme_preference.dart          # Persistência de tema (Claro/Escuro/Sistema e Paleta)
    └── widgets/                       # LibraryView, ReaderPage, SettingsView, AudioPlayerControlBar
```

---

## 6. Como Executar e Testar

### 6.1. Pré-requisitos
* Flutter SDK (versão 3.29 ou superior)
* Dispositivo Android (Android 8+ / ARM64) ou sistema Windows 10/11.

### 6.2. Executando no Windows
```bash
flutter pub get
flutter run -d windows
```

### 6.3. Executando no Celular Android
Conecte o smartphone via cabo USB com a depuração USB habilitada:
```bash
flutter devices
flutter run -d <id-do-dispositivo>
```

### 6.4. Instalando o Modelo Supertonic 3 no Android (Opcional)
Para habilitar o motor Supertonic 3 no dispositivo Android via ADB:
```bash
adb push .planning/tmp/supertonic-extracted/sherpa-onnx-supertonic-3-tts-int8-2026-05-11 /sdcard/Download/supertonic
```
O aplicativo detectará os modelos automaticamente ao iniciar e os direcionará para a pasta restrita da C++ (`/storage/emulated/0/Android/data/com.example.tcc_tts_neural/files/supertonic`).

---

## 7. Testes Automatizados

O projeto mantém **100% de aprovação** na suíte de testes unitários e de integração:

```bash
# Executar toda a suíte de testes
flutter test

# Executar testes por domínio
flutter test test/core/document/epub_parser_test.dart
flutter test test/ui/theme_contract_test.dart
flutter test test/core/config_test.dart
flutter test test/core/pipeline/pipeline_streaming_test.dart
```

---

## 8. Plataformas Suportadas e Escopo

* **Android** (Foco principal móvel; testado e homologado em dispositivo físico Motorola G85 5G - Android 15 / API 35).
* **Windows** (Foco desktop para desenvolvimento, testes de carga e benchmarks).



---

## 9. Finalidade Acadêmica

Trabalho de Conclusão de Curso (TCC) desenvolvido para apresentação no curso de **Engenharia de Computação da Universidade Estadual de Feira de Santana (UEFS)**.
