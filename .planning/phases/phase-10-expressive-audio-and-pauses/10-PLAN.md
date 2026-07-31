# PLAN: Fase 10 - Processador Avançado de Pausas & Ritmo Humano por Pontuação

## 🎯 Visão Geral da Fase
Implementação do algoritmo de ritmo e pausas humanas por pontuação inspirado no VoxSherpa-TTS (`AudioEmotionHelper.java`), focado na injeção de silêncios PCM dinâmicos entre pontuações com jitter estocástico (±10%) e ajuste proporcional à velocidade de reprodução.

---

## 📦 Tarefas de Implementação

### Tarefa 1: Implementar `PunctuationPauseHelper`
- **Arquivo**: `lib/core/audio/punctuation_pause_helper.dart`
- **Responsabilidade**:
  - Mapear pontuações (`,`, `.`, `!`, `?`, `...`) para durações base (140ms a 380ms).
  - Gerar buffers de bytes PCM 16-bit com valor 0 para taxas de amostragem dinâmicas (16kHz, 22.05kHz, 24kHz).
  - Aplicar jitter de ±10% e ajuste de velocidade (`silenceMs / speed`).

### Tarefa 2: Integrar o Controle de Intensidade de Pausa na UI
- **Arquivo**: `lib/ui/widgets/audio_player_control_bar.dart` / `lib/main.dart`
- **Responsabilidade**:
  - Adicionar controle de intensidade de pausas no leitor para permitir ajuste em tempo de execução.

### Tarefa 3: Suíte de Testes Automatizados
- **Arquivo**: `test/core/audio/punctuation_pause_helper_test.dart`
- **Responsabilidade**:
  - Validar a precisão de milissegundos e tamanho de bytes dos buffers de silêncio para 16kHz, 22.05kHz e 24kHz.
  - Garantir que todos os 64+ testes do projeto continuem 100% verdes.

---

## 🧪 Verificação & Critérios de Conclusão
- Executar `flutter test` e garantir 0 falhas.
- Executar `flutter analyze` e garantir 0 erros/warnings.
