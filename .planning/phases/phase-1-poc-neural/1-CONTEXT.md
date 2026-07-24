# Contexto e Decisões de Arquitetura - Fase 1: Inferência Neural Core

## Directivas Principais do Usuário
1. **Código Fácil de Entender (Legibilidade & Clareza)**:
   - Funções curtas, focadas e com única responsabilidade (Single Responsibility Principle).
   - Nomes de variáveis e funções altamente expressivos e em português/inglês padronizados.
   - Anotações de tipo explícitas (Type Hints) e Docstrings explicativas no topo dos módulos e funções.
2. **Modularização Rigorosa**:
   - Componentes 100% desacoplados e testáveis isoladamente.
   - Divisão clara de pastas/módulos: `core/config`, `core/engine`, `core/audio`, `core/metrics`.
3. **Foco em Otimização de Desempenho**:
   - Reutilização de instâncias da engine/sessão ONNX (evitar reloads caros).
   - Medição exata de tempo de inferência e alocação de memória.
   - Garantia de Real-Time Factor ($\text{RTF} < 1.0$).

---

## Decisões Fixadas para o Desenvolvimento Modular

### 1. Estratégia de Modularização e Testes
- **Abordagem Incremental**: O projeto será construído através de pacotes/módulos independentes e desacoplados, onde cada módulo tem sua própria suite de testes unitários antes de ser integrado.
- **Estrutura Core em Módulos**:
  - `core/engine`: Carregamento do modelo ONNX e execução da inferência.
  - `core/audio`: Leitura, manipulação e exportação de amostras de áudio (WAV/PCM).
  - `core/metrics`: Cálculo de RTF ($\text{RTF} = t_{\text{inferência}} / t_{\text{áudio}}$) e telemetria de latência.
  - `core/config`: Gerenciamento de caminhos, configurações de modelo e hiperparâmetros de inferência.

### 2. Escolha da Engine e Modelo VITS ONNX
- **Engine**: `sherpa-onnx` (ou `piper` ONNX runtime) por oferecer suporte nativo C++/Python/Dart de altíssimo desempenho para Edge Computing.
- **Modelo Acústico**: VITS em Português do Brasil (`pt_BR`) otimizado em ONNX (modelo quantizado em int8 ou fp32 de baixo peso ~50-80MB).

### 3. Escopo do Primeiro MVP (Para Apresentação ao Orientador - Fase 5)
- **O que conterá no MVP**:
  1. Carregamento de um arquivo `.epub` real.
  2. Extração do texto do Capítulo 1.
  3. Fatiamento em sentenças e normalização PLN das frases.
  4. Inferência local com o modelo VITS ONNX.
  5. Geração e reprodução de áudio fluído + exibição do relatório de **RTF (Real-Time Factor)** na tela/terminal.
- **O que será deixado para depois do MVP**:
  - Buffer circular assíncrono avançado com threads de purge de RAM (Milestone 2).
  - Telemetria de bateria/CPU em segundo plano no dispositivo móvel (Milestone 3).

### 4. Metodologia de Testes
- Cada módulo deverá passar por **testes unitários automatizados** antes de ser integrado à pipeline principal.
- Para a Fase 1, o critério de sucesso é a passagem no teste de inferência com $\text{RTF} < 1.0$.
