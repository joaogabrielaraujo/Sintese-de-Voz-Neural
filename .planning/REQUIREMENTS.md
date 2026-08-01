# Requisitos do Projeto de TCC

## Requisitos Funcionais (RF)

- [x] **RF-01 (Extração de EPUB)**: O sistema deve abrir arquivos `.epub`, descompactar os conteúdos XHTML/HTML internos e extrair o texto estruturado limpo por capítulos.
  - *Status*: **Concluído** (Fase 4 - `lib/core/epub/epub_parser.dart` e `html_sanitizer.dart`).
- [x] **RF-02 (Normalização PLN / TTS-Norm)**: O sistema deve converter numerais (cardinais e ordinais), siglas, moedas e caracteres especiais para suas formas por extenso em Português do Brasil.
  - *Status*: **Concluído** (Fase 2 - `lib/core/nlp/tts_normalizer.dart`).
- [x] **RF-03 (Fatiamento de Sentenças)**: O sistema deve segmentar o fluxo contínuo de texto em sentenças coerentes para envio incremental ao sintetizador.
  - *Status*: **Concluído** (Fase 3 - `lib/core/segmenter/sentence_segmenter.dart`).
- [x] **RF-04 (Síntese de Voz Neural 100% Offline)**: O sistema deve executar um motor de inferência local (Sherpa-onnx / Piper TTS) carregando modelo VITS ONNX sem depender de nenhuma chamada de rede (Cloud AI).
  - *Status*: **Concluído** (Fase 1 - `lib/core/engine/sherpa_onnx_engine.dart`).
- [x] **RF-05 (Buffer Circular Assíncrono & Pipeline Orquestradora)**: O sistema deve utilizar threads assíncronas concorrentes para produzir sintetizações de áudio em background enquanto consome/reproduz a sentença atual, liberando buffers já escutados para evitar vazamento de memória (OOM).
  - *Status*: **Concluído** (Fase 5 - `lib/core/pipeline/pipeline_orchestrator.dart`).
- [x] **RF-06 (Coleta de Telemetria / Logs)**: O sistema deve registrar métricas de inferência: tempo de síntese, duração do áudio gerado, cálculo de RTF (Real-Time Factor) e perfil de CPU.
  - *Status*: **Concluído** (Fase 1 e Fase 5 - `lib/core/metrics/rtf_calculator.dart` e `pipeline_result.dart`).
- [ ] **RF-07 (Navegação estrutural e mídia EPUB)**: O sistema deve apresentar a navegação exatamente conforme o sumário declarado pelo EPUB, preservando ordem, hierarquia e itens auxiliares. Deve renderizar toda imagem referenciada no conteúdo XHTML na posição original, resolvendo recursos internos e caminhos relativos sem rede. O fluxo de PLN/TTS deve receber somente blocos de texto e ignorar integralmente imagens e seus textos alternativos, sem anunciá-los ao usuário.
  - *Status*: **Planejado**.

---

## Requisitos Não-Funcionais (RNF)

- [x] **RNF-01 (Execução Offline)**: 100% dos processamentos (EPUB -> PLN -> Inferência ONNX -> Reprodução) devem ser executados localmente no dispositivo (Edge Computing).
  - *Status*: **Concluído**.
- [x] **RNF-02 (Fator de Tempo Real - RTF < 1.0)**: O tempo de inferência para cada sentença deve ser menor do que a duração total do áudio sintetizado ($\text{RTF} = \frac{t_{\text{inferência}}}{t_{\text{áudio}}} < 1.0$), garantindo reprodução fluida sem interrupções.
  - *Status*: **Concluído** (Validado na suíte de testes com RTF < 0.10).
- [x] **RNF-03 (Gerenciamento Restrito de Memória)**: A pegada de memória RAM durante a leitura de um livro longo não deve crescer linearmente com o tamanho do capítulo, mantendo-se estável através do fatiamento e purge automático de sentenças processadas.
  - *Status*: **Concluído**.
- [x] **RNF-04 (Portabilidade Móvel)**: O motor de inferência e a aplicação devem ser compatíveis com a plataforma Flutter e dispositivos móveis (Android / iOS / Desktop / Web).
  - *Status*: **Concluído**.
