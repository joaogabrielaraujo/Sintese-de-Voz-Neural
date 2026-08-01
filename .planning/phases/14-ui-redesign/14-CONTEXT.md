---
phase: 14-ui-redesign
status: planned
depends_on: [13.7]
---

# Fase 14 — Redesign da UI e Leitor Responsivo

## Objetivo

Aplicar ao aplicativo Flutter a linguagem visual definida em `design_mockup.html`, mantendo a operação offline, o leitor sincronizado e as métricas do TCC. A interface deve funcionar em Android e Windows, com adaptação real ao tamanho da janela e aos dispositivos de entrada.

## Decisões

- O mockup é referência visual; não será embutido como HTML.
- Android prioriza leitura vertical, controles acessíveis ao toque e navegação inferior.
- Windows usa layout largo com navegação lateral, mouse, teclado e conteúdo centralizado.
- O redesign não altera o pipeline de síntese, importação, fila, memória, RTF ou MOS.
- Fontes externas não serão carregadas pela rede em runtime; usar fontes empacotadas ou fallbacks locais.
