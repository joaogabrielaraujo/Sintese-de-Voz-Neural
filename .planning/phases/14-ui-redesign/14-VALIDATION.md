---
phase: 14
slug: ui-redesign
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-03
---

# Phase 14 — Validation Strategy

> Contrato de validação incremental para implementar o redesign editorial nativo sem regressões no pipeline offline.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` do Flutter SDK 3.44.8 |
| **Config file** | `analysis_options.yaml`; sem configuração golden dedicada |
| **Quick run command** | `flutter test --no-pub test/ui/theme_contract_test.dart test/ui/redesign_widgets_test.dart` |
| **Full suite command** | `flutter test --no-pub` |
| **Estimated runtime** | Medir na Wave 0; manter feedback por tarefa abaixo de 120 segundos |

---

## Sampling Rate

- **After every task commit:** teste focal do arquivo/comportamento tocado e `dart analyze` dos arquivos modificados
- **After every plan wave:** suíte de UI completa nos temas claro e escuro
- **Before `$gsd-verify-work`:** `flutter test --no-pub`, análise sem erros, goldens aprovados, guidelines de acessibilidade e UAT Android/Windows
- **Max feedback latency:** 120 segundos para a amostra focal; suítes longas devem ser registradas como janela de verificação

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-W0-01 | W0 | 0 | Fontes e temas locais | — | Assets locais; nenhuma dependência de rede | unit/widget | `flutter test --no-pub test/ui/theme_contract_test.dart` | ❌ W0 | ⬜ pending |
| 14-W0-02 | W0 | 0 | Fixtures e viewports | — | Estado isolado e determinístico | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart` | ⚠️ parcial | ⬜ pending |
| 14-NAV | TBD | TBD | Navegação responsiva | — | Foco e ações consistentes | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name navigation` | ⚠️ parcial | ⬜ pending |
| 14-LIB | TBD | TBD | Biblioteca/importação | — | Erros preservam biblioteca e progresso | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name biblioteca` | ⚠️ parcial | ⬜ pending |
| 14-READ | TBD | TBD | Leitor editorial | — | Erros preservam livro e posição | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name leitor` | ⚠️ parcial | ⬜ pending |
| 14-PLAY | TBD | TBD | Player e métricas | — | Falhas são recuperáveis e não inventam métricas | widget/integration | `flutter test --no-pub test/ui/audio_player_widget_test.dart test/ui/telemetry_flow_test.dart` | ⚠️ parcial | ⬜ pending |
| 14-A11Y | TBD | TBD | Atalhos, foco e acessibilidade | — | Controles rotulados e alcançáveis | guideline/widget | `flutter test --no-pub test/ui/accessibility_test.dart` | ❌ W0 | ⬜ pending |
| 14-GOLD | TBD | TBD | Fidelidade visual | — | N/A | golden | `flutter test --no-pub test/ui/golden_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/parcial*

---

## Wave 0 Requirements

- [ ] Adquirir e versionar Spectral, Archivo e Space Mono, incluindo licenças e pesos 400/600.
- [ ] Criar `test/ui/theme_contract_test.dart` para tokens, famílias, tamanhos, pesos e preferência claro/escuro/sistema.
- [ ] Criar factories de fixtures para biblioteca, leitor e player.
- [ ] Criar helper de viewport, janela baixa e `TextScaler.linear(2.0)` com reset seguro.
- [ ] Criar `test/ui/accessibility_test.dart` com tap targets, rótulos e contraste.
- [ ] Criar `test/ui/golden_test.dart` e baselines canônicos somente após fontes e tokens estabilizarem.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fidelidade editorial final | Paridade visual com `vozlume_redesign.html` | Comparação de hierarquia e densidade exige julgamento humano | Comparar Biblioteca e Leitor lado a lado em claro/escuro nos viewports 390×844, 800×1280 e 1440×900. |
| Android físico | Safe areas, toque, rotação e TTS offline | Depende do dispositivo G85 e engine nativa | Executar importação, leitura, play/pause, retomada, tema e rotação no G85. |
| Windows nativo | Redimensionamento, mouse e teclado | Depende do runner Windows real | Validar 320px, 899/900px, 1440×900, `Ctrl+O`, Space, Escape, setas e foco. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
