---
phase: 14
slug: ui-redesign
status: approved
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-03
---

# Phase 14 â€” Validation Strategy

> Contrato de validaÃ§Ã£o incremental para implementar o redesign editorial nativo sem regressÃµes no pipeline offline.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` do Flutter SDK 3.44.8 |
| **Config file** | `analysis_options.yaml`; sem configuraÃ§Ã£o golden dedicada |
| **Quick run command** | `flutter test --no-pub test/ui/theme_contract_test.dart test/ui/redesign_widgets_test.dart` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | Medir na Wave 0; manter feedback por tarefa abaixo de 120 segundos |

---

## Sampling Rate

- **After every task commit:** teste focal do arquivo/comportamento tocado e `dart analyze` dos arquivos modificados
- **After every plan wave:** suÃ­te de UI completa nos temas claro e escuro
- **Before `$gsd-verify-work`:** `flutter test --no-pub`, anÃ¡lise sem erros, goldens aprovados, guidelines de acessibilidade e UAT Android/Windows
- **Max feedback latency:** 120 segundos para a amostra focal; suÃ­tes longas devem ser registradas como janela de verificaÃ§Ã£o

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-04-T1 | 14-04 | 1 | Fontes e temas locais | â€” | Assets locais; nenhuma dependÃªncia de rede | unit/widget | `flutter test --no-pub test/ui/theme_contract_test.dart` | âŒ W0 | â¬œ pending |
| 14-04-T2 | 14-04 | 1 | Preferência e harness de tema | â€” | Estado isolado e determinÃ­stico | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart` | âš ï¸ parcial | â¬œ pending |
| 14-NAV | TBD | TBD | NavegaÃ§Ã£o responsiva | â€” | Foco e aÃ§Ãµes consistentes | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name navigation` | âš ï¸ parcial | â¬œ pending |
| 14-LIB | TBD | TBD | Biblioteca/importaÃ§Ã£o | â€” | Erros preservam biblioteca e progresso | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name biblioteca` | âš ï¸ parcial | â¬œ pending |
| 14-READ | 14-07 | 4 | Leitor editorial | â€” | Erros preservam livro e posiÃ§Ã£o | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name leitor` | âš ï¸ parcial | â¬œ pending |
| 14-PLAY | TBD | TBD | Player e mÃ©tricas | â€” | Falhas sÃ£o recuperÃ¡veis e nÃ£o inventam mÃ©tricas | widget/integration | `flutter test --no-pub test/ui/audio_player_widget_test.dart test/ui/telemetry_flow_test.dart` | âš ï¸ parcial | â¬œ pending |
| 14-A11Y | 14-08 | 5 | Atalhos, foco e acessibilidade | â€” | Controles rotulados e alcanÃ§Ã¡veis | guideline/widget | `flutter test --no-pub test/ui/accessibility_test.dart` | âŒ W0 | â¬œ pending |
| 14-GOLD | 14-09 | 6 | Fidelidade visual | â€” | N/A | golden | `flutter test --no-pub test/ui/golden_test.dart` | âŒ W0 | â¬œ pending |

*Status: â¬œ pending Â· âœ… green Â· âŒ red Â· âš ï¸ flaky/parcial*

---

## Wave 0 Requirements

- [ ] Adquirir e versionar Spectral, Archivo e Space Mono, incluindo licenÃ§as e pesos 400/600.
- [ ] Criar `test/ui/theme_contract_test.dart` para tokens, famÃ­lias, tamanhos, pesos e preferÃªncia claro/escuro/sistema.
- [ ] Criar factories de fixtures para biblioteca, leitor e player.
- [ ] Criar helper de viewport, janela baixa e `TextScaler.linear(2.0)` com reset seguro.
- [ ] Criar `test/ui/accessibility_test.dart` com tap targets, rÃ³tulos e contraste.
- [ ] Criar `test/ui/golden_test.dart` e baselines canÃ´nicos somente apÃ³s fontes e tokens estabilizarem.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fidelidade editorial final | Paridade visual com `vozlume_redesign.html` | ComparaÃ§Ã£o de hierarquia e densidade exige julgamento humano | Comparar Biblioteca e Leitor lado a lado em claro/escuro nos viewports 390Ã—844, 800Ã—1280 e 1440Ã—900. |
| Android fÃ­sico | Safe areas, toque, rotaÃ§Ã£o e TTS offline | Depende do dispositivo G85 e engine nativa | Executar importaÃ§Ã£o, leitura, play/pause, retomada, tema e rotaÃ§Ã£o no G85. |
| Windows nativo | Redimensionamento, mouse e teclado | Depende do runner Windows real | Validar 320px, 899/900px, 1440Ã—900, `Ctrl+O`, Space, Escape, setas e foco. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
