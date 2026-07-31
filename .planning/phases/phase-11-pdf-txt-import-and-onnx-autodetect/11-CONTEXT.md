# CONTEXT: Fase 11 - Importação de PDF/TXT & Auto-Detecção de Modelos ONNX

## 🎯 Objetivo
Expandir o leitor de documentos do projeto para aceitar arquivos nos formatos `.pdf` e `.txt` (além dos arquivos `.epub` já suportados), e implementar a auto-detecção de modelos ONNX (baseada na contagem de tokens do `tokens.txt` e taxa de amostragem), inspirada no algoritmo de inspeção do **VoxSherpa-TTS** (`VoiceEngine.java`).

---

## 🛠️ Decisões Arquiteturais Locked

### 1. Suporte Multi-Formato de Documentos (`DocumentParserFactory`)
- **`TxtParser`**: Leitura direta de arquivos `.txt` em UTF-8, dividindo em parágrafos e capítulos por quebras de linha duplas.
- **`PdfParser`**: Extração limpa de texto de arquivos `.pdf`, removendo números de página e mantendo o fluxo contínuo para o `SentenceSegmenter`.
- **`EpubParser`**: Mantido e reutilizado de forma transparente.

### 2. Auto-Detecção de Modelos ONNX (`OnnxModelDetector`)
- **Análise do `tokens.txt`**:
  - Contagem de linhas `< 200`: Modelo MMS baseado em caracteres (não requer `espeak-ng-data`).
  - Contagem de linhas `>= 200`: Modelo Piper/VITS baseado em fonemas (requer `espeak-ng-data`).
- **Taxa de Amostragem Automática**:
  - Leitura das propriedades do modelo (16000 Hz, 22050 Hz, 24000 Hz) para inclusão nos cabeçalhos WAV gerados pelo `WavWriter`.

---

## 📋 Critérios de Aceitação
- [ ] Classe `TxtParser` e `PdfParser` criadas em `lib/core/document/`.
- [ ] `OnnxModelDetector` criado em `lib/core/engine/onnx_model_detector.dart`.
- [ ] Testes unitários cobrindo a extração de TXT, PDF e a detecção de modelos.
- [ ] 100% dos testes do projeto aprovados.
