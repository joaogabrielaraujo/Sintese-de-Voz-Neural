# Síntese de Voz Neural Offline

Leitor EPUB em Flutter/Dart com síntese neural PT-BR offline usando Sherpa-ONNX, modelo VITS e streaming de áudio por frases.

Projeto de TCC de João Gabriel Araújo Almeida, Engenharia de Computação — UEFS.

## Estado atual

O fluxo principal já funciona assim:

1. A pessoa seleciona um arquivo `.epub` pelo seletor do dispositivo.
2. O arquivo é validado e lido a partir dos bytes do ZIP.
3. O parser localiza `container.xml`, o OPF e a ordem de leitura da `spine`.
4. O livro e seus capítulos ficam disponíveis no Home.
5. O Reader abre em uma tela própria, com seta para retornar ao Home.
6. O capítulo é dividido em frases e sintetizado incrementalmente.
7. Apenas uma pequena janela de áudio fica em memória.
8. A frase atual é destacada e o usuário pode selecionar outra frase.
9. A mudança de ponto só acontece após confirmar “Continuar da frase N”.

O áudio não é sintetizado inteiro antes da reprodução. A fila usa backpressure e libera os buffers após o consumo, reduzindo o risco de travamento em livros grandes.

## Funcionalidades implementadas

- Importação real de EPUB no Android e Windows.
- Validação de extensão, ZIP, `META-INF/container.xml`, OPF e capítulos.
- Suporte a EPUBs com imagens, fontes e outros recursos binários.
- Resolução de caminhos relativos e nomes codificados por URL.
- Seleção de capítulos pela ordem do `spine`.
- Tela separada de leitura com retorno ao Home.
- Streaming limitado de áudio por frases.
- Seleção de frase com confirmação explícita antes de reposicionar a leitura.
- Player com play/pause, parada, velocidade e progresso.
- Motores Sherpa-ONNX, Sherpa-ONNX CLI e failover configurável.
- Normalização de datas, moedas, numerais, símbolos e abreviações em PT-BR.
- Preservação de acentos e cedilha até o motor fonético.
- Tratamento de numerais romanos, como `Capítulo II` → `Capítulo dois`.
- Normalização de palavras inteiras em maiúsculas sem soletrá-las indevidamente.

## Arquitetura

```text
Arquivo EPUB
    ↓
Document picker → EpubBytesImporter → EpubParser
    ↓
EpubBook / EpubChapter
    ↓
SentenceSegmenter
    ↓
TTSNormalizer → PhoneticNormalizer
    ↓
PipelineOrchestrator
    ↓
CircularAudioBuffer com capacidade limitada
    ↓
AudioPlayerService → audioplayers
```

Principais diretórios:

- `lib/core/document/`: picker, importador ZIP, parser EPUB, sanitização e modelos.
- `lib/core/text/`: segmentação, normalização textual e preparação fonética.
- `lib/core/pipeline/`: processamento completo e streaming por frases.
- `lib/core/memory/`: fila FIFO, backpressure e liberação de buffers.
- `lib/core/engine/`: contrato TTS, Sherpa-ONNX, CLI, mock e failover.
- `lib/core/audio/`: player, WAV e serviços de áudio.
- `lib/ui/widgets/`: leitor, destaque de frases, controles e avaliação MOS.
- `test/`: testes de parser, importação, normalização, fila, pipeline, áudio e widgets.
- `.planning/`: roadmap, contexto e planos executáveis do projeto.

## Requisitos

- Flutter com Dart `>=3.0.0 <4.0.0`.
- Modelo `pt_BR-faber-medium.onnx`.
- `tokens.txt` compatível com o modelo.
- Diretório `espeak-ng-data` completo para conversão grafema-fonema PT-BR.

Os modelos ficam em `assets/models/`. O aplicativo copia os arquivos necessários para o diretório local da aplicação durante a inicialização da engine.

## Executar

```bash
flutter pub get
flutter run
```

Para testar especificamente no Windows:

```bash
flutter run -d windows
```

## Testes e análise

```bash
flutter analyze
flutter test
```

Os testes cobrem, entre outros pontos:

- EPUB válido, inválido, corrompido e com recursos binários.
- OPF aninhado, `href` relativo e nomes codificados.
- Numerais romanos, siglas, maiúsculas, acentos e cedilha.
- Backpressure, cancelamento e liberação de memória.
- Streaming a partir de uma frase escolhida.
- Destaque e controles do player.

Se os comandos Flutter não produzirem saída e expirarem, verifique processos antigos da Dart VM antes de concluir que existe uma falha no código. A validação manual no Windows e no Android continua necessária para o seletor de arquivos e o áudio nativo.

## Próximas fases

### Leitor visual fiel ao EPUB

O próximo refinamento do Reader é renderizar o XHTML original do capítulo, preservando títulos, parágrafos, itálico, listas e imagens sempre que possível. As frases continuarão existindo apenas como âncoras internas para destacar o trecho atual e permitir “Continuar daqui”.

### Qualidade fonética

Continuar a avaliação A/B de palavras como `desacopladas`, `ação`, `coração`, `execução`, `síntese` e numerais romanos, evitando regras fonéticas globais sem evidência auditiva.

### Persistência e experiência de leitura

- Salvar posição por livro e capítulo.
- Biblioteca de EPUBs importados.
- Marcadores e histórico de leitura.
- Busca no texto.
- Opção de acompanhar ou não a frase atual durante a rolagem.

### Avaliação do TCC

- Testes com livros curto, médio e longo.
- Medição de RTF, RAM, CPU, latência inicial e pausas entre frases.
- Avaliação MOS e preparação dos resultados da monografia.

## Licença e finalidade

Projeto acadêmico desenvolvido para monografia e Trabalho de Conclusão de Curso (TCC) na UEFS.
