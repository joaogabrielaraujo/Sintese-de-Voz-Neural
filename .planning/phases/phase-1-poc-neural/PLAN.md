# Plano de Execução Detalhado - Fase 1: Motor de Inferência Neural Core (PoC ONNX)

## Contexto & Diretrizes de Desenvolvimento
- **Facilidade de Entendimento (Legibilidade)**: Funções focadas, nomes descritivos em português/inglês padronizados, anotações de tipo (`Type Hints`) e docstrings em todos os módulos.
- **Modularização Rigorosa**: Código divido em submódulos desacoplados (`core/config`, `core/engine`, `core/audio`, `core/metrics`). Cada submódulo possui responsabilidade única e interface bem definida.
- **Foco em Otimização**:
  - Sessão da engine de inferência inicializada uma única vez (evitar reloads dispendiosos).
  - Manipulação eficiente de buffers de áudio PCM em memória para mitigar overhead de alocação.
  - Cálculo contínuo do Fator de Tempo Real ($\text{RTF} = t_{\text{inferência}} / t_{\text{áudio}}$) buscando $\text{RTF} < 1.0$.

---

## Estrutura Modular Proposta para a Fase 1

```
TCC/
├── assets/
│   └── models/               # Modelos ONNX (pt_BR) e arquivos de configuração/tokens
├── core/
│   ├── __init__.py
│   ├── config.py             # Módulo de configuração de caminhos e hiperparâmetros
│   ├── engine.py             # Wrapper modular da engine ONNX (Sherpa-onnx / Piper)
│   ├── audio.py              # Módulo otimizado para salvamento e manipulação de WAV
│   └── metrics.py            # Telemetria de desempenho (tempo, RTF e memória)
├── tests/
│   ├── __init__.py
│   ├── test_config.py        # Testes de configuração e validação de paths
│   ├── test_audio.py         # Testes do utilitário de áudio
│   ├── test_metrics.py       # Testes da fórmula de RTF
│   └── test_engine.py        # Testes de integração da inferência neural local
└── requirements.txt          # Dependências mínimas do projeto
```

---

## Tarefas de Execução (Slices Modulares)

### Tarefa 1.1: Setup da Infraestrutura Modular & Gerenciamento de Assets (`core/config`)
- **Descrição**: Criar a estrutura básica de diretórios e o módulo `core/config.py` encarregado de validar a existência e resolver caminhos dos modelos ONNX (`pt_BR`) e parâmetros da síntese.
- **Princípio de Otimização & Legibilidade**: Configurações imutáveis usando dataclasses/Pydantic ou constantes tipadas simples e claras.
- **Arquivos**:
  - `core/config.py`
  - `tests/test_config.py`
- **Verificação**: Testes unitários validando resolução de caminhos e lançando exceções claras caso arquivos do modelo não estejam presentes.

### Tarefa 1.2: Utilitário de Manipulação e Exportação de Áudio (`core/audio`)
- **Descrição**: Desenvolver o módulo `core/audio.py` focado na validação de taxas de amostragem (ex: 22050 Hz), formatos de buffer PCM/float32 e exportação limpa para WAV sem alocações desnecessárias.
- **Princípio de Otimização & Legibilidade**: Funções puras (`save_wav`, `get_audio_duration`), uso de estruturas de array nativas ou NumPy otimizado.
- **Arquivos**:
  - `core/audio.py`
  - `tests/test_audio.py`
- **Verificação**: Teste unitário gerando uma onda senoidal ou buffer de teste e verificando a integridade e tempo exato do arquivo WAV gerado.

### Tarefa 1.3: Módulo de Telemetria & Cálculo de RTF Baseline (`core/metrics`)
- **Descrição**: Desenvolver `core/metrics.py` com a classe/função `PerformanceTracker` para capturar latência de inferência ($t_{\text{inferência}}$), duração do áudio ($t_{\text{áudio}}$) e calcular a taxa $\text{RTF}$:
  $$\text{RTF} = \frac{t_{\text{inferência}}}{t_{\text{áudio}}}$$
- **Princípio de Otimização & Legibilidade**: Medição de alta precisão usando `time.perf_counter()`, interface intuitiva e formateadores de log legíveis.
- **Arquivos**:
  - `core/metrics.py`
  - `tests/test_metrics.py`
- **Verificação**: Testes unitários com tempos simulados confirmando asserção da fórmula e formatação do relatório de performance.

### Tarefa 1.4: Motor de Inferência Neural ONNX Core (`core/engine`)
- **Descrição**: Implementar a classe `TTSEngine` em `core/engine.py` com carregamento otimizado (singleton/lazy loading) da engine Sherpa-onnx/Piper, expondo o método de inferência `synthesize(text: str) -> AudioBuffer`.
- **Princípio de Otimização & Legibilidade**: Reutilização de sessão ONNX em memória, tratamento claro de erros, type hints explícitos.
- **Arquivos**:
  - `core/engine.py`
  - `tests/test_engine.py`
- **Verificação**: Teste de inferência real com a frase `"Testando inferência neural offline de voz em Português."`, garantindo áudio não nulo e $\text{RTF} < 1.0$.

---

## Critérios de Aceite da Fase 1 (Verification Gate)
- [ ] Código escrito com **alta clareza e legibilidade** (Type Hints + Docstrings + Funções Puras).
- [ ] Estrutura **100% modular** em `core/config`, `core/audio`, `core/metrics` e `core/engine`.
- [ ] O modelo VITS ONNX em Português sintetiza áudio sem dependência de internet.
- [ ] A taxa de tempo real atinge $\text{RTF} < 1.0$ em execução local.
- [ ] A suite completa de testes unitários (`pytest` / `unittest`) executa e passa com 100% de sucesso.
