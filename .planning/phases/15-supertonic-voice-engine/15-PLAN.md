---
phase: 15-supertonic-voice-engine
plan: 01
type: execute
wave: 1
depends_on: [14]
autonomous: false
files_modified:
  - pubspec.yaml
  - lib/core/engine/tts_engine_type.dart
  - lib/core/engine/composite_tts_engine.dart
  - lib/core/engine/sherpa_onnx_engine.dart
  - lib/ui/widgets/settings_view.dart
  - test/core/engine/supertonic_engine_test.dart
  - test/ui/settings_view_test.dart
---

# Plano 15-01 — Validar e integrar o Supertonic 3 com segurança

## Objetivo

Validar primeiro a viabilidade do Supertonic 3 para português brasileiro em Windows e no Motorola G85 e, somente após um gate explícito de aprovação, integrá-lo ao pipeline offline existente com fallback para Piper/VITS.

O plano não presume consumo inferior a 150 MB. Tamanho dos artefatos, pico de RAM, latência de inicialização e RTF serão resultados experimentais usados para decidir se o motor pode ser habilitado no dispositivo.

## Restrições técnicas

- Manter execução 100% offline durante a síntese.
- Usar suporte oficial do `sherpa_onnx` ao Supertonic 3; esse suporte requer versão 1.13.2 ou superior.
- Tratar o modelo como um pacote composto por `duration_predictor`, `text_encoder`, `vector_estimator`, `vocoder`, `tts.json`, `unicode_indexer.bin` e arquivo de estilo de voz.
- Não substituir nem remover Piper/VITS. Ele permanece como motor padrão/fallback até a aprovação do gate de viabilidade.
- Não empacotar centenas de MB no APK sem medir o impacto. Comparar assets embarcados com instalação/download local explícito e persistente.
- Preservar cancelamento, descarte de buffers e limites do pipeline implementados nas fases anteriores.

## Tarefas

### 1. Baseline e atualização controlada do sherpa-onnx

- Registrar a versão atual (`1.10.15`) e executar os testes relevantes de engine, streaming e UI antes da atualização.
- Atualizar `sherpa_onnx` para uma versão compatível com Supertonic 3 (mínimo 1.13.2).
- Confirmar na API Dart/Flutter disponível como configurar o modelo Supertonic e selecionar `lang=pt`.
- Reexecutar os testes existentes e uma inicialização Piper no Windows antes de avançar.

**Aceite:** a aplicação compila e o comportamento Piper existente não apresenta regressão automatizada.

### 2. POC isolada de síntese PT-BR

- Obter o pacote oficial quantizado Supertonic 3 e registrar origem, versão, licença, hashes e tamanho de cada arquivo.
- Criar uma POC isolada, sem UI e sem alterar ainda o motor padrão.
- Gerar WAV PCM válido usando `lang=pt`, voz fixa identificada e parâmetros reprodutíveis.
- Usar um corpus PT-BR curto com perguntas, exclamações, vírgulas, números, moedas, datas, siglas e nomes brasileiros.
- Registrar latência de primeira síntese, RTF, duração e erros de pronúncia observados.

**Aceite:** ao menos uma amostra PT-BR válida é produzida offline no Windows, sem crash ou saída vazia.

### 3. Gate de viabilidade — decisão go/no-go

Apresentar os resultados da POC antes de implementar a integração completa:

- qualidade auditiva PT-BR aceitável em comparação ao Piper;
- tamanho total instalado;
- pico de RAM e RAM estabilizada após descarte;
- RTF e latência de primeira síntese;
- compatibilidade do binding Flutter no Windows;
- estratégia viável para disponibilizar os assets sem tornar o APK impraticável.

**Decisão:**

- **GO:** prosseguir para integração, Android e UI;
- **GO com restrições:** disponibilizar Supertonic apenas em plataformas/dispositivos compatíveis;
- **NO-GO:** manter Piper como padrão e registrar Supertonic como resultado experimental da Fase 15.

Este checkpoint requer julgamento humano e não pode ser aprovado somente por testes automatizados.

### 4. Integração no CompositeTTSEngine

Executar somente após GO ou GO com restrições.

- Preferir adaptar a configuração do `SherpaOnnxTTSEngine` existente ao tipo Supertonic em vez de criar um runtime ONNX paralelo.
- Criar `SupertonicOnnxEngine` somente se a API ou o ciclo de vida forem materialmente diferentes e justificarem uma estratégia separada.
- Registrar o tipo em `TTSEngineType` e no `CompositeTTSEngine`.
- Preservar fallback para Piper e, depois, para o motor nativo já suportado.
- Garantir que falha de asset, incompatibilidade nativa e pressão de memória não derrubem o processo.

**Aceite:** selecionar Supertonic produz `AudioBuffer`; uma falha induzida ativa o fallback e mantém o pipeline utilizável.

### 5. Assets e ciclo de vida

- Implementar validação de presença, versão e integridade do pacote do modelo.
- Carregar os grafos apenas quando o motor for selecionado.
- Liberar sessões e buffers ao trocar de motor ou encerrar o pipeline.
- Registrar tamanho instalado e pico de memória como telemetria; `<150 MB` é meta aspiracional, não requisito bloqueante.
- Impedir que arquivos incompletos sejam tratados como modelo válido.

**Aceite:** ausência/corrupção de qualquer componente gera erro recuperável e fallback; a troca repetida de motores não apresenta crescimento monotônico de RAM.

### 6. Seletor e persistência na UI

- Exibir “Supertonic 3 — experimental” apenas quando a plataforma e os assets forem compatíveis.
- Reutilizar o seletor existente em `SettingsView`; não criar uma segunda superfície concorrente.
- Persistir a preferência, mas retornar ao fallback quando o modelo não estiver disponível na próxima inicialização.
- Informar tamanho e disponibilidade local sem prometer desempenho não medido.

**Aceite:** a seleção é acessível, persistente e não deixa a aplicação sem motor funcional.

### 7. Validação Android/Windows e avaliação do TCC

- Repetir o corpus no Windows e no Motorola G85.
- No Android, instalar e iniciar o app real; compilação do APK isoladamente não conta como validação.
- Medir RTF, primeira latência, pico de RAM e estabilidade durante leitura contínua.
- Comparar Piper e Supertonic com a mesma máquina, texto, configuração e método.
- Para MOS, definir escala de 1–5, corpus fixo, reprodução aleatória/cega e quantidade de avaliadores; não apresentar uma única opinião como MOS conclusivo.

**Aceite:** resultados reprodutíveis são registrados para ambas as plataformas, ou as limitações observadas são documentadas como resultado experimental.

## Verificação

- Testes unitários do mapeamento de configuração e validação do pacote de assets.
- Teste de integração da síntese para `AudioBuffer` PCM não vazio.
- Teste de fallback com modelo ausente/corrompido.
- Regressão dos testes existentes de engine, streaming, cancelamento e configurações.
- Evidência manual de áudio PT-BR no corpus definido.
- Evidência de execução real no Motorola G85 e Windows, com métricas comparáveis.

## Critérios de sucesso

1. A atualização do sherpa-onnx não quebra o Piper existente.
2. A POC gera áudio PT-BR offline antes de qualquer expansão de UI.
3. A decisão go/no-go é baseada em qualidade, compatibilidade, tamanho, RAM e RTF medidos.
4. Quando aprovado, o Supertonic integra o pipeline sem remover o fallback atual.
5. Falha ou ausência do modelo é recuperável e nunca deixa o leitor inutilizável.
6. As conclusões acadêmicas distinguem medições objetivas de avaliação perceptual.

