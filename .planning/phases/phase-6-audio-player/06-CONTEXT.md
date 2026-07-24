# Contexto & Decisões de Implementação - Fase 6

## 🎯 Objetivo da Fase 6
Integrar a reprodução de áudio diretamente no aplicativo móvel em Flutter, permitindo que o usuário e o orientador escutem a voz sintetizada pelo modelo neural ONNX (`pt_BR-faber-medium.onnx` ou mock de demonstração) a partir de capítulos de livros EPUB.

---

## 📋 Decisões de Arquitetura e Implementação

### 1. Pacote de Reprodução de Áudio
- **Decisão**: Utilizar a biblioteca `audioplayers` (ou `just_audio`) no Flutter para gerenciar a reprodução de dados de áudio PCM/WAV gerados pelo `PipelineOrchestrator`.
- **Justificativa**: Compatibilidade nativa com Android, iOS e Desktop, além de baixo consumo de recursos e controle direto de estado (Play, Pause, Stop, Seek).

### 2. Fluxo de Reprodução (PoC Auditiva)
- O `PipelineOrchestrator` sintetiza a sentença/capítulo e gera o buffer de áudio WAV.
- O `AudioPlayerController` recebe esse buffer e envia para a saída de áudio física (alto-falantes ou fones de ouvido).

### 3. Interface de Usuário (UI Player)
- Adicionar ao `main.dart` / componentes de UI:
  - Botão de **Play / Pause** de reprodução de voz.
  - **Barra de Progresso (SeekBar)** com o tempo decorrido do áudio.
  - Indicador da sentença atual em leitura.
  - Seletor de velocidade da síntese (ex: 1.0x, 1.25x, 1.5x).

### 4. Validação de Qualidade Perceptual (MOS - Mean Opinion Score)
- Possibilitar a avaliação direta de:
  - Prosódia e naturalidade em Português do Brasil (`pt-BR`).
  - Clareza na pronúncia de numerais, datas e abreviações tratados pelo módulo PLN (Fase 2).
  - Presença de ruídos ou artefatos no modelo ONNX.

---

## ⏩ Próximos Passos
- Gerar o plano detalhado de implementação (PLAN.md).
