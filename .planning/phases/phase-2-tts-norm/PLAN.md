# Plano de Execução Detalhado - Fase 2: Módulo PLN de Normalização de Texto (TTS-Norm)

## Objetivo
Criar o módulo puramente funcional `lib/core/nlp/` em Dart/Flutter para pré-processar textos em Português do Brasil (`pt_BR`), convertendo numerais, ordinais, valores monetários (`R$`), datas, siglas e símbolos especiais em frases por extenso adequadas para síntese de voz neural.

---

## Estrutura Modular Proposta

```
lib/core/nlp/
├── number_to_words.dart         # Conversor de números cardinais e ordinais para extenso em PT-BR
├── currency_normalizer.dart     # Conversor de valores monetários em Reais (ex: "R$ 150,00" -> "cento e cinquenta reais")
├── date_time_normalizer.dart    # Conversor de datas e horários (ex: "24/07/2026" -> "vinte e quatro de julho...")
├── abbreviation_normalizer.dart # Expansor de siglas e abreviações (ex: "Dr." -> "Doutor", "UEFS" -> "U E F S")
└── tts_normalizer.dart          # Pipeline orquestrador unificado de normalização

test/core/nlp/
├── number_to_words_test.dart
├── currency_normalizer_test.dart
├── date_time_normalizer_test.dart
├── abbreviation_normalizer_test.dart
└── tts_normalizer_test.dart
```

---

## Tarefas de Execução (Slices Modulares)

### Tarefa 2.1: Extenso de Numerais Cardinais e Ordinais (`number_to_words.dart`)
- **Descrição**: Desenvolver algoritmo recursivo/iterativo puro em Dart que converta qualquer número inteiro (de `0` a `999.999.999`) e numerais ordinais (`1º` a `999º`) para sua grafia por extenso em Português BR.
- **Exemplos**:
  - `0` -> `"zero"`
  - `150` -> `"cento e cinquenta"`
  - `2026` -> `"dois mil e vinte e seis"`
  - `1º` -> `"primeiro"`, `2ª` -> `"segunda"`
- **Arquivos**: `lib/core/nlp/number_to_words.dart`, `test/core/nlp/number_to_words_test.dart`
- **Verificação**: Suíte de testes unitários com pelo menos 20 casos numéricos cobrindo unidades, dezenas, centenas, milhares e ordinais.

### Tarefa 2.2: Normalizador de Valores Monetários em Reais (`currency_normalizer.dart`)
- **Descrição**: Desenvolver parser Regex em Dart para identificar padrões do tipo `R$ X,YY` ou `R$ X` e converter para texto por extenso de reais e centavos.
- **Exemplos**:
  - `R$ 150,00` -> `"cento e cinquenta reais"`
  - `R$ 1,50` -> `"um real e cinquenta centavos"`
  - `R$ 0,50` -> `"cinquenta centavos"`
- **Arquivos**: `lib/core/nlp/currency_normalizer.dart`, `test/core/nlp/currency_normalizer_test.dart`
- **Verificação**: Testes unitários com valores no singular/plural, centavos isolados e montantes elevados.

### Tarefa 2.3: Normalizador de Datas e Horários (`date_time_normalizer.dart`)
- **Descrição**: Desenvolver regras de expressão regular para extrair formatos de data (`DD/MM/AAAA`, `DD/MM`) e hora (`HH:MM`, `HHhMM`) e convertê-los em texto corrido.
- **Exemplos**:
  - `24/07/2026` -> `"vinte e quatro de julho de dois mil e vinte e seis"`
  - `14:30` -> `"quatorze horas e trinta minutos"`
- **Arquivos**: `lib/core/nlp/date_time_normalizer.dart`, `test/core/nlp/date_time_normalizer_test.dart`
- **Verificação**: Testes unitários validando meses, anos do século XXI e variações de horário.

### Tarefa 2.4: Expansor de Siglas, Abreviações e Símbolos (`abbreviation_normalizer.dart`)
- **Descrição**: Módulo para mapear e expandir abreviações comuns (`Dr.`, `Dra.`, `pág.`, `Prof.`, `etc.`), símbolos (`%` -> `por cento`, `&` -> `e`, `+` -> `mais`) e formatar siglas (`UEFS` -> `U E F S`).
- **Arquivos**: `lib/core/nlp/abbreviation_normalizer.dart`, `test/core/nlp/abbreviation_normalizer_test.dart`
- **Verificação**: Testes unitários validando textos contendo múltiplas siglas e símbolos intercalados.

### Tarefa 2.5: Pipeline Orquestrador Unificado (`tts_normalizer.dart`)
- **Descrição**: Integrar todos os conversores anteriores na classe `TTSNormalizer.normalize(String input) -> String`, executando os passos em sequência otimizada e higienizando espaços duplicados e pontuações desnecessárias.
- **Arquivos**: `lib/core/nlp/tts_normalizer.dart`, `test/core/nlp/tts_normalizer_test.dart`
- **Verificação**: Teste de ponta a ponta com parágrafos reais de livros contendo números, datas, valores e siglas em uma única frase.

---

## Critérios de Aceite da Fase 2 (Verification Gate)
- [ ] O módulo `TTSNormalizer` converte corretamente textos complexos sem alterar o sentido do conteúdo.
- [ ] 100% das funções do módulo PLN são puras, determinísticas e sem efeito colateral.
- [ ] A suíte de testes unitários para a Fase 2 passa com 100% de sucesso.
