# Plano de Execução Detalhado - Fase 5: PRIMEIRO MVP (Demonstração Funcional para o Orientador)

## Objetivo
Integrar os 4 módulos desenvolvidos (`core/epub`, `core/segmenter`, `core/nlp`, `core/engine`) em uma fachada unificada (`PipelineOrchestrator`) e entregar a aplicação funcional do **Primeiro MVP** em Flutter com suporte a síntese por streaming, relatórios de RTF e demonstração ao orientador.

---

## Estrutura Modular Proposta

```
lib/core/pipeline/
├── pipeline_result.dart        # Modelo de dados com telemetria consolidada e formato de relatório do TCC
└── pipeline_orchestrator.dart  # Fachada unificada que conecta EPUB -> Segmenter -> PLN -> ONNX Engine

test/core/pipeline/
└── pipeline_orchestrator_test.dart # Teste de integração de ponta-a-ponta da pipeline completa
```

---

## Tarefas de Execução (Slices Modulares)

### Tarefa 5.1: Fachada Orquestradora & Relatório de Desempenho (`pipeline_orchestrator.dart`)
- **Descrição**: Desenvolver o orquestrador `PipelineOrchestrator` que aceita instâncias de `ITTSEngine` e processa capítulos de livros EPUB encadeando a extração, fatiamento, normalização gramatical e síntese de áudio, retornando o objeto imutável `PipelineResult`.
- **Arquivos**: `lib/core/pipeline/pipeline_result.dart`, `lib/core/pipeline/pipeline_orchestrator.dart`
- **Verificação**: Teste unitário validando a execução do capítulo e a consistência das estatísticas de áudio e tempo.

### Tarefa 5.2: Suíte de Testes End-to-End (`pipeline_orchestrator_test.dart`)
- **Descrição**: Criar testes de integração ponta a ponta simulando um livro EPUB completo com parágrafos contendo numerais, datas e moedas, garantindo que o relatório final confirme $\text{RTF} < 1.0$.
- **Arquivos**: `test/core/pipeline/pipeline_orchestrator_test.dart`
- **Verificação**: Passagem de 100% dos testes da pipeline.

### Tarefa 5.3: Interface de Usuário Final do Primeiro MVP (`main.dart`)
- **Descrição**: Finalizar o aplicativo Flutter `lib/main.dart` transformando-o em um leitor de demonstração completo para o orientador, contendo:
  - Seletor/Carregador de arquivos EPUB.
  - Exibição estruturada dos capítulos do livro.
  - Sincronização visual de leitura por sentença.
  - Painel de controle de áudio (Play/Pause/Reset).
  - Cartão de telemetria de hardware com indicador visual verde para $\text{RTF} < 1.0$.
- **Arquivos**: `lib/main.dart`
- **Verificação**: Validação visual e de experiência de usuário no aplicativo Flutter.

---

## Critérios de Aceite da Fase 5 (Verification Gate - Milestone 1 MVP)
- [ ] O `PipelineOrchestrator` executa o fluxo completo do EPUB à síntese de forma limpa e modular.
- [ ] A aplicação gera um relatório de RTF consistente confirmando viabilidade em tempo real ($\text{RTF} < 1.0$).
- [ ] A interface do leitor permite alternar e sintetizar o Capítulo 1 de um livro EPUB.
- [ ] 100% dos testes unitários e de integração do projeto passam com sucesso (`flutter test`).
