# Síntese de Voz Neural Offline em Dispositivos Móveis

## Leitor EPUB baseado em Edge Computing, Sherpa-ONNX e VITS

Projeto de Trabalho de Conclusão de Curso desenvolvido por **João Gabriel Araújo Almeida**, no curso de Engenharia de Computação da Universidade Estadual de Feira de Santana (UEFS), sob orientação do Prof. Matheus Giovanni.

O objetivo é construir um leitor de livros digitais capaz de importar arquivos EPUB, extrair seus capítulos e reproduzi-los por síntese de voz neural em português brasileiro, sem depender de serviços remotos ou conexão com a internet durante a leitura.

---

## 1. Visão geral

Aplicações de leitura em voz alta precisam resolver dois problemas diferentes:

1. interpretar documentos reais, que podem conter estruturas EPUB complexas, capítulos fragmentados, imagens, fontes, nomes codificados e diferentes formas de organização do manifesto;
2. produzir áudio continuamente sem tentar sintetizar um livro inteiro de uma vez.

Este projeto trata o EPUB como uma fonte de documento e a síntese como um fluxo incremental. O capítulo é dividido em frases, cada frase passa por normalização linguística e é enviada ao motor TTS. O áudio é colocado em uma fila limitada, reproduzido e liberado após o consumo.

```text
EPUB selecionado
      │
      ▼
Seletor nativo de documentos
      │ bytes
      ▼
Validação ZIP / EPUB
      │
      ▼
container.xml → OPF → manifest → spine
      │
      ▼
EpubBook / EpubChapter
      │ texto limpo
      ▼
SentenceSegmenter
      │ frases
      ▼
TTSNormalizer + PhoneticNormalizer
      │ texto PT-BR
      ▼
Sherpa-ONNX / VITS
      │ PCM Float32
      ▼
CircularAudioBuffer limitado
      │
      ▼
AudioPlayerService / audioplayers
```

---

## 2. Estado atual do produto

O fluxo funcional disponível atualmente é:

1. A pessoa inicia no Home.
2. Seleciona um arquivo `.epub` pelo seletor do dispositivo.
3. O arquivo é lido por bytes, sem exigir uma permissão ampla de armazenamento.
4. A aplicação valida o ZIP e localiza a estrutura EPUB.
5. Metadados e capítulos são carregados na ordem definida pela `spine`.
6. O aplicativo abre uma tela própria de leitura.
7. O usuário escolhe um capítulo e inicia a leitura.
8. O capítulo é segmentado em frases para o TTS.
9. Somente uma janela pequena de áudio é mantida em memória.
10. A frase ativa recebe destaque visual.
11. O usuário pode tocar em outra frase para selecioná-la.
12. A troca só ocorre depois da confirmação “Continuar da frase N”.
13. A seta no canto superior esquerdo encerra a leitura e retorna ao Home.

O áudio não é concatenado nem sintetizado integralmente antes da reprodução. Essa decisão é essencial para que livros grandes não provoquem uma alocação de memória proporcional ao capítulo inteiro.

---

## 3. Objetivos técnicos

### 3.1. Execução offline

O modelo neural é carregado localmente e a inferência é executada no dispositivo. O fluxo de leitura não envia o texto do livro para servidores externos.

### 3.2. Baixo consumo de memória

A aplicação usa uma fila FIFO com capacidade limitada. O produtor sintetiza frases e aguarda quando a fila está cheia. O consumidor reproduz o áudio e libera o buffer depois que a frase termina.

Esse mecanismo evita o fluxo problemático:

```text
Capítulo inteiro → todas as frases → todos os WAVs → reprodução
```

O fluxo implementado é:

```text
Frase atual + poucas frases de margem → reprodução incremental
```

### 3.3. Baixa latência entre frases

O áudio é produzido antecipadamente pela fila enquanto a frase atual toca. A transição foi otimizada para evitar validações WAV redundantes e trabalho desnecessário no limite entre uma frase e outra.

### 3.4. Qualidade linguística em PT-BR

O pipeline expande datas, valores monetários, ordinais, símbolos, abreviações, siglas e numerais romanos. Acentos e cedilha são preservados até a engine configurada com os dados do `espeak-ng`.

---

## 4. Importação e interpretação de EPUB

### 4.1. Seletor de documentos

`NativeEpubDocumentPicker` cria uma fronteira testável entre a interface e o pacote `file_picker`. O seletor é filtrado para EPUB, mas o filtro de extensão é apenas uma primeira proteção; o conteúdo também é validado.

O fluxo tenta obter os bytes diretamente. No Windows, quando o plugin fornece apenas um caminho local, a aplicação usa esse caminho como fallback controlado para ler os bytes. No Android, o fluxo prioriza o documento selecionado pelo Storage Access Framework.

### 4.2. Validações

O importador verifica:

- extensão `.epub`;
- tamanho mínimo do arquivo;
- limite máximo de importação;
- assinatura de arquivo ZIP;
- presença de `META-INF/container.xml`;
- localização do arquivo OPF;
- existência de capítulos legíveis;
- caminhos relativos e nomes percent-encoded;
- ausência de traversal de caminho (`..`) para fora do arquivo.

Recursos binários como imagens, capas, fontes e arquivos multimídia não são convertidos para UTF-8. Apenas arquivos textuais relevantes ao parser são decodificados.

### 4.3. Estrutura EPUB utilizada

O parser segue a estrutura padrão:

```text
META-INF/container.xml
        │ aponta para
        ▼
OPS/package.opf
        ├── metadata
        ├── manifest
        └── spine
                │ ordem de leitura
                ▼
        capítulo.xhtml / capítulo.html
```

O `manifest` associa IDs a arquivos. A `spine` define a ordem de leitura. Por isso, a quantidade de partes encontrada em um livro pode ser maior do que a quantidade de capítulos impressos: livros comerciais frequentemente dividem capítulos em vários XHTMLs, páginas preliminares, seções e anexos.

### 4.4. Módulos envolvidos

- `lib/core/document/selected_document.dart`: abstração do documento escolhido.
- `lib/core/document/epub_bytes_importer.dart`: validação ZIP e conversão dos bytes em arquivos textuais.
- `lib/core/document/epub_parser.dart`: leitura de OPF, manifest e spine.
- `lib/core/document/html_sanitizer.dart`: remoção de tags para o texto utilizado pelo TTS.
- `lib/core/document/epub_model.dart`: modelos `EpubBook` e `EpubChapter`.

---

## 5. Pipeline de texto e fonética

### 5.1. Segmentação

`SentenceSegmenter` transforma o texto limpo em `TextSentence`. Cada frase possui:

- índice absoluto no capítulo;
- texto original limpo;
- indicação de fim de parágrafo;
- quantidade de caracteres e palavras;
- estimativa de duração.

O índice absoluto é importante porque a fila de áudio usa apenas uma pequena janela. A interface continua sabendo que uma frase pertence, por exemplo, ao índice 37 do capítulo mesmo que ela seja o segundo item atualmente carregado na memória.

### 5.2. Normalização linguística

`TTSNormalizer` executa as etapas de preparação do texto:

1. remove tags HTML e caracteres de controle;
2. expande moedas;
3. expande datas e horários;
4. converte ordinais;
5. converte números cardinais;
6. expande abreviações, símbolos e siglas;
7. normaliza espaços e pontuação.

Exemplos:

```text
R$ 150,00  → cento e cinquenta reais
24/07/2026 → vinte e quatro de julho de dois mil e vinte e seis
100%       → cem por cento
UEFS       → U E F S
```

### 5.3. Maiúsculas e numerais romanos

A camada `AbbreviationNormalizer` diferencia três situações:

- siglas conhecidas, como `TCC`, `UEFS`, `ONNX`, `PDF` e `HTML`, são soletradas;
- palavras inteiras em maiúsculas, como `ARQUITETURA` e `AÇÃO`, são convertidas para forma normal;
- numerais romanos, como `II`, `III` e `XIV`, são convertidos para palavras portuguesas.

Exemplos:

```text
Capítulo II → Capítulo dois
AÇÃO        → ação
TCC         → T C C
```

### 5.4. Preservação fonética

O modelo PT-BR usa os dados do `espeak-ng` para auxiliar a conversão grafema-fonema. Por isso, o aplicativo não remove globalmente `ç`, `ã`, `é`, `ê`, `ó` ou outros diacríticos antes da inferência.

`PhoneticNormalizer` atualmente é conservador: remove caracteres invisíveis e espaços problemáticos, mas não aplica substituições fonéticas genéricas. Alterações como `ç` → `s` ou `gu` → outra grafia só devem ser introduzidas depois de testes A/B auditivos, pois uma regra que melhora uma palavra pode piorar várias outras.

Palavras usadas na avaliação fonética incluem:

- desacopladas;
- ação;
- coração;
- execução;
- arquitetura;
- síntese;
- órgão;
- palavras com `gue`, `gui`, `que` e `qui`.

---

## 6. Motor TTS e áudio

### 6.1. Contrato de engine

`ITTSEngine` define a interface comum para inicialização, síntese, métricas e descarte de recursos. Isso permite trocar o motor sem alterar o parser ou a interface do leitor.

Implementações disponíveis:

- `SherpaOnnxTTSEngine`: engine neural via FFI C++;
- `SherpaOnnxCliEngine`: integração alternativa via executável CLI;
- `MockTTSEngine`: motor determinístico para testes;
- `CompositeTTSEngine`: seleção e failover entre engines.

### 6.2. Modelo configurado

O perfil padrão utiliza:

- `pt_BR-faber-medium.onnx`;
- `tokens.txt`;
- `espeak-ng-data`;
- taxa de amostragem de 22050 Hz;
- execução CPU;
- `lengthScale` configurável para velocidade da fala.

Os arquivos necessários ficam em `assets/models/` e são copiados para o diretório local da aplicação durante a inicialização.

### 6.3. Buffer e fila

`CircularAudioBuffer` implementa o padrão produtor-consumidor:

- o produtor sintetiza e enfileira;
- quando a capacidade é atingida, o produtor aguarda;
- o consumidor retira o próximo item;
- o áudio atual só é liberado depois da reprodução;
- cancelamento libera itens pendentes e desbloqueia operações aguardando espaço.

### 6.4. WAV

`WavWriter` serializa amostras Float32 em PCM16 RIFF/WAV. A validação e os testes do formato ficam no utilitário, sem repetir a decodificação completa a cada troca de frase durante a leitura.

### 6.5. Player

`AudioPlayerService` encapsula `audioplayers` e oferece:

- carregar áudio em memória;
- tocar e pausar;
- parar;
- alterar velocidade;
- buscar posição;
- acompanhar posição, duração e estado.

O fluxo de streaming também protege contra eventos de conclusão duplicados, que poderiam fazer o leitor avançar duas frases.

---

## 7. Interface do aplicativo

### 7.1. Home

O Home concentra:

- importação de EPUB;
- metadados do livro;
- seleção de capítulo;
- seleção de engine;
- status da importação;
- acesso à tela de leitura.

### 7.2. Reader

O Reader é uma parte separada do aplicativo. A barra superior possui uma seta para voltar ao Home. Ao retornar:

- a fila de áudio é cancelada;
- o áudio é interrompido;
- buffers pendentes são liberados;
- a pessoa pode selecionar outro livro.

A leitura atual usa o texto contínuo do capítulo com marcações de frase. O objetivo da próxima evolução visual é renderizar o XHTML original, preservando estilos, títulos, listas, imagens e demais elementos sempre que possível, aplicando somente a marcação sobre o trecho falado.

### 7.3. Seleção confirmada

O toque em uma frase não muda imediatamente a posição da leitura. Ele cria uma seleção pendente, visualmente diferente da frase ativa. A pessoa pode cancelar ou confirmar:

```text
Toque no trecho
      ↓
Trecho selecionado
      ├── Cancelar seleção
      └── Continuar da frase N
```

Após a confirmação, a fila antiga é cancelada e o pipeline começa no índice absoluto escolhido.

### 7.4. Destaque e acompanhamento

A frase atual recebe destaque visual para permitir acompanhamento com os olhos. O auto-scroll deve ser usado com cuidado: se a pessoa rolar manualmente, o leitor não deve forçá-la de volta para a frase ativa.

---

## 8. Estrutura do repositório

```text
lib/
├── main.dart
├── core/
│   ├── audio/
│   │   ├── audio_player_service.dart
│   │   ├── audio_player_service_interface.dart
│   │   ├── mock_audio_player_service.dart
│   │   └── wav_writer.dart
│   ├── config/
│   │   └── tts_config.dart
│   ├── document/
│   │   ├── epub_bytes_importer.dart
│   │   ├── epub_model.dart
│   │   ├── epub_parser.dart
│   │   ├── html_sanitizer.dart
│   │   └── selected_document.dart
│   ├── engine/
│   │   ├── composite_tts_engine.dart
│   │   ├── mock_tts_engine.dart
│   │   ├── sherpa_onnx_cli_engine.dart
│   │   ├── sherpa_onnx_engine.dart
│   │   └── tts_engine_interface.dart
│   ├── memory/
│   │   ├── circular_audio_buffer.dart
│   │   ├── memory_manager.dart
│   │   └── sentence_audio_item.dart
│   ├── metrics/
│   ├── pipeline/
│   │   ├── pipeline_orchestrator.dart
│   │   └── pipeline_result.dart
│   └── text/
│       ├── abbreviation_normalizer.dart
│       ├── phonetic_normalizer.dart
│       ├── sentence_model.dart
│       ├── sentence_segmenter.dart
│       └── tts_normalizer.dart
├── ui/
│   └── widgets/
│       ├── audio_player_control_bar.dart
│       ├── reader_document_view.dart
│       ├── sentence_highlight_view.dart
│       └── ...
└── test/
```

Os testes ficam no diretório `test/`, organizados por domínio: documento, texto, pipeline, memória, áudio, engine e UI.

---

## 9. Como executar

### Dependências

```bash
flutter pub get
```

### Windows

```bash
flutter run -d windows
```

### Android

```bash
flutter devices
flutter run -d <id-do-dispositivo>
```

O fluxo Android utiliza o seletor de documentos do sistema e não deve solicitar permissão ampla de armazenamento para selecionar um EPUB.

### Análise e testes

```bash
flutter analyze
flutter test
```

Testes específicos úteis:

```bash
flutter test test/core/document/epub_bytes_importer_test.dart
flutter test test/core/document/epub_parser_test.dart
flutter test test/core/text/abbreviation_normalizer_test.dart
flutter test test/core/text/phonetic_normalizer_test.dart
flutter test test/core/pipeline/pipeline_start_index_test.dart
flutter test test/ui/audio_player_widget_test.dart
```

Em alguns ambientes Windows deste projeto, processos antigos da Dart VM podem impedir que `flutter test`, `flutter analyze` ou `dart format` retornem. Quando isso ocorrer, é necessário verificar os processos ativos antes de interpretar o timeout como falha funcional.

---

## 10. Estratégia de testes manuais

### Importação

1. Abrir o aplicativo.
2. Selecionar um EPUB real com imagens e capítulos longos.
3. Confirmar título, autor e quantidade de capítulos.
4. Trocar de capítulo.
5. Voltar ao Home pela seta.
6. Importar outro EPUB.

### Streaming

1. Abrir um capítulo grande.
2. Iniciar a leitura.
3. Confirmar que a primeira frase começa antes do capítulo inteiro ser sintetizado.
4. Observar se as transições entre frases não apresentam pausas longas.
5. Parar a leitura e iniciar novamente.

### Seleção de ponto

1. Tocar em uma frase distante.
2. Confirmar que apenas a seleção pendente muda.
3. Verificar que o áudio atual não é interrompido antes da confirmação.
4. Pressionar “Continuar da frase N”.
5. Confirmar que a fila antiga foi descartada e a leitura começa no ponto selecionado.

### Fonética

Testar frases contendo:

```text
Capítulo II.
AÇÃO e ARQUITETURA.
TCC, UEFS e ONNX.
Ação, coração, órgão e síntese.
Desacopladas, execução, que, qui, gue e gui.
```

---

## 11. Métricas e avaliação acadêmica

O projeto calcula o Real-Time Factor (RTF):

```text
RTF = tempo de inferência / duração do áudio produzido
```

Interpretação:

- `RTF < 1.0`: a síntese é mais rápida do que a reprodução;
- `RTF = 1.0`: síntese e reprodução têm velocidade equivalente;
- `RTF > 1.0`: o processamento pode não acompanhar a leitura contínua.

As próximas avaliações devem registrar:

- latência até o primeiro áudio;
- tempo de transição entre frases;
- RTF por frase e por capítulo;
- memória durante livros curtos, médios e longos;
- uso de CPU;
- velocidade selecionada;
- quantidade de frases processadas;
- avaliações perceptuais MOS;
- falhas de importação ou síntese.

---

## 12. Decisões de engenharia

### Por que não sintetizar o livro inteiro?

Porque o áudio PCM cresce proporcionalmente ao texto. Em livros longos, combinar todo o capítulo em memória aumenta a latência inicial e pode causar OOM. O streaming permite começar cedo e manter o consumo limitado.

### Por que preservar os acentos?

O perfil PT-BR usa dados de conversão grafema-fonema. Remover `ç`, `ã` ou acentos antes da engine altera a entrada linguística e pode produzir pronúncia incorreta.

### Por que separar Home e Reader?

O Home representa a biblioteca/seleção do documento. O Reader representa uma sessão de leitura com capítulo, cursor, fila, player e marcação visual. Separar esses estados reduz o risco de importar outro livro enquanto uma fila antiga ainda está tocando.

### Por que exigir confirmação ao escolher uma frase?

A seleção e a ação de interromper/reiniciar áudio são operações diferentes. A confirmação evita que um toque acidental altere imediatamente a leitura atual.

---

## 13. Próximas fases

### Renderização fiel do XHTML

Substituir a apresentação textual simplificada por uma renderização do XHTML original do capítulo, preservando títulos, parágrafos, itálico, negrito, listas e imagens quando suportados. As frases continuarão recebendo IDs internos para sincronização.

### Fonética contextual

Expandir a avaliação A/B para palavras problemáticas sem criar substituições globais frágeis. As regras devem ser acompanhadas por testes de texto e avaliação auditiva.

### Persistência da leitura

- posição por livro e capítulo;
- último ponto reproduzido;
- biblioteca local;
- marcadores;
- histórico;
- busca no texto.

### Avaliação final do TCC

- benchmarks de livros reais;
- tabelas de RTF, RAM e CPU;
- comparação de velocidades;
- avaliação MOS;
- documentação da arquitetura;
- preparação da monografia e dos slides da banca.

---

## 14. Planejamento GSD

O diretório `.planning/` contém a documentação de evolução do projeto:

- `PROJECT.md`: visão e restrições do produto;
- `REQUIREMENTS.md`: requisitos funcionais e não funcionais;
- `ROADMAP.md`: fases e marcos;
- `phases/`: contextos, planos, contratos de UI e verificações;
- `debug/`: investigações técnicas persistentes.

As fases recentes documentam a importação real de EPUB, a fila de áudio, a proteção contra OOM, a qualidade fonética e o Reader com seleção confirmada. Foi utilizado, o framework Get the Shit Done.

---

## 15. Finalidade e licença

Este repositório é um projeto acadêmico destinado à monografia e ao Trabalho de Conclusão de Curso em Engenharia de Computação na UEFS.
