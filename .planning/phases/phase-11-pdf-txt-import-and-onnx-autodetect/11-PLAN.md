# PLAN: Fase 11 - Importação de PDF/TXT & Auto-Detecção de Modelos ONNX

## 🎯 Visão Geral da Fase
Implementar parsers para documentos TXT e PDF, permitindo que a aplicação converta arquivos de texto simples e PDF em áudio neural, e construir o utilitário `OnnxModelDetector` para inspecionar automaticamente a contagem de tokens e a amostragem de modelos ONNX (com base nas lições do VoxSherpa-TTS).

---

## 📦 Tarefas de Implementação

### Tarefa 1: Implementar Parsers de Documento (`TxtParser` e `PdfParser`)
- **Arquivos**: `lib/core/document/txt_parser.dart`, `lib/core/document/pdf_parser.dart`
- **Responsabilidade**:
  - `TxtParser`: Extrair capítulos de arquivos de texto puro (`.txt`).
  - `PdfParser`: Sanitizar e extrair páginas/capítulos de documentos PDF (`.pdf`).

### Tarefa 2: Implementar `OnnxModelDetector`
- **Arquivo**: `lib/core/engine/onnx_model_detector.dart`
- **Responsabilidade**:
  - Inspecionar arquivo `tokens.txt` para diferenciar modelos MMS (caracteres) e Piper (fonemas).
  - Retornar a configuração otimizada de `dataDir` e taxa de amostragem.

### Tarefa 3: Integrar e Escrever Testes Unitários
- **Arquivos**: `test/core/document/document_parser_test.dart`, `test/core/engine/onnx_model_detector_test.dart`
- **Responsabilidade**:
  - Testar parsing de arquivos `.txt` e `.pdf`.
  - Testar detecção de modelo MMS vs VITS.
  - Garantir 0 falhas na suíte total de testes (`flutter test`).

---

## 🧪 Verificação & Critérios de Conclusão
- Executar `flutter test` e verificar 100% de sucesso.
- Executar `flutter analyze` sem erros.
