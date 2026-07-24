# Contexto e Decisões de Arquitetura - Fase 2: Módulo PLN de Normalização de Texto (TTS-Norm)

## Objetivos da Fase
Desenvolver o módulo puramente funcional `lib/core/nlp/` em Dart/Flutter para pré-processar e normalizar textos em Português do Brasil (`pt_BR`), convertendo símbolos, números, moedas, siglas e datas em suas formas por extenso adequadas para sintetizadores de voz neural (ONNX/VITS).

---

## Decisões de Arquitetura e Design

### 1. Funcionalidade Puramente Modular (Pure Functions)
- **Desacoplamento**: O módulo `TTSNormalizer` não deve ter dependências de UI ou de IO. Recebe uma `String` e retorna uma `String` higienizada e por extenso.
- **Pipelines Encadeados**: Estruturado como um pipeline de transformações regex/funções puras:
  1. Limpeza de HTML/Controle.
  2. Normalização de Moedas (`R$`).
  3. Normalização de Datas (`DD/MM/AAAA`) e Horários (`HH:MM`).
  4. Normalização de Numerais Ordinais (`1º`, `2ª`).
  5. Normalização de Numerais Cardinais (`150`, `2026`).
  6. Expansão de Siglas e Abreviações (`UEFS`, `Dr.`, `pág.`, `%`).
  7. Higienização Final de Pontuação e Espaçamento.

### 2. Padrão de Desempenho e Memória
- Reutilização de instâncias pré-compiladas de `RegExp`.
- Zero vazamentos de memória e execução em tempo linear $\mathcal{O}(n)$ em relação ao tamanho da frase.

### 3. Cobertura de Testes Unitários
- Cada regra de normalização deve ter testes isolados com casos normais e de borda (ex: `R$ 0,00`, `1º de janeiro`, `UEFS`).
