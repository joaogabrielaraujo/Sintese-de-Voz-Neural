# Plano de Execução Detalhado - Fase 3: Fatiador de Sentenças (Sentence Segmenter)

## Objetivo
Criar o módulo puramente funcional `lib/core/segmenter/` em Dart/Flutter para fatiar fluxos de texto contínuos de livros e artigos em sentenças sintaticamente coerentes (`TextSentence`), respeitando pontuação, diálogos, proteção de abreviações e limites de tamanho para inferência neural.

---

## Estrutura Modular Proposta

```
lib/core/segmenter/
├── sentence_model.dart      # Modelo de dados imutável TextSentence (índice, texto, isParagraphEnd)
└── sentence_segmenter.dart  # Algoritmo funcional de fatiamento e proteção de abreviações

test/core/segmenter/
├── sentence_model_test.dart # Testes do modelo de dados
└── sentence_segmenter_test.dart # Testes unitários do fatiador com casos reais de livros/artigos
```

---

## Tarefas de Execução (Slices Modulares)

### Tarefa 3.1: Modelo de Dados `TextSentence` (`sentence_model.dart`)
- **Descrição**: Desenvolver a classe imutável `TextSentence` representando uma sentença fatiada com metadados para sincronização (índice da sentença, texto limpo, contagem de caracteres e indicador de fim de parágrafo).
- **Arquivos**: `lib/core/segmenter/sentence_model.dart`, `test/core/segmenter/sentence_model_test.dart`
- **Verificação**: Teste unitário validando imutabilidade, cálculo de propriedades derivadas e conversão para string/map.

### Tarefa 3.2: Algoritmo Core de Fatiamento de Sentenças (`sentence_segmenter.dart`)
- **Descrição**: Desenvolver a classe `SentenceSegmenter` com a função estática `List<TextSentence> segment(String text, {int maxSentenceLength = 200})`.
- **Regras**:
  - Proteção contra quebra em abreviações conhecidas (`Dr.`, `Prof.`, `pág.`, `Sr.`, `Sra.`, `etc.`, `ed.`, `vol.`).
  - Fatiamento em pontuação final de frase (`.`, `!`, `?`, `...`).
  - Suporte a travessões e aspas de diálogos.
  - Sub-divisão suave (*soft split*) por vírgula ou pontuação secundária caso uma sentença exceda `maxSentenceLength`.
- **Arquivos**: `lib/core/segmenter/sentence_segmenter.dart`, `test/core/segmenter/sentence_segmenter_test.dart`
- **Verificação**: Testes unitários com casos de borda (diálogos de livros, citações com abreviações, reticências e parágrafos extensos).

### Tarefa 3.3: Integração no Pipeline da UI de Demonstração (`main.dart`)
- **Descrição**: Atualizar o aplicativo de demonstração Flutter `lib/main.dart` para exibir a lista de sentenças fatiadas antes da síntese, permitindo visualização gráfica da segmentação e cálculo de latência por sentença.
- **Arquivos**: `lib/main.dart`
- **Verificação**: Teste de interface demonstrando a entrada de um parágrafo longo de livro sendo fatiado em sentenças individuais e processado pela pipeline.

---

## Critérios de Aceite da Fase 3 (Verification Gate)
- [ ] O módulo `SentenceSegmenter` fatia textos longos em sentenças coerentes sem quebrar abreviações.
- [ ] Frases longas que excedam o limite configurado são fatiadas suavemente por pontuação secundária.
- [ ] 100% das funções do módulo `lib/core/segmenter/` são puras e imutáveis.
- [ ] A suíte de testes unitários da Fase 3 passa com 100% de sucesso.
