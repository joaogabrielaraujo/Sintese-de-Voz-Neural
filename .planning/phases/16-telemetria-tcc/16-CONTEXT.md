---
phase: 16-telemetria-tcc
status: planned
depends_on: [15]
---

# Fase 16 — Telemetria e avaliação quantitativa para o TCC

## Objetivo

Medir o comportamento do sistema em aparelho real e no Windows após o release candidate e a integração do motor de voz neural expressivo estarem estáveis.

## Dimensões

- Latência até o primeiro áudio (TTFA - Time to First Audio);
- Pausa entre frases e fluidez de reprodução;
- Real-Time Factor (RTF) por frase, capítulo e por motor (Piper vs Supertonic 3);
- RAM mínima, média e pico de consumo;
- CPU durante síntese e reprodução;
- Bateria e temperatura em sessões longas de leitura de EPUB;
- Falhas de importação, engine e reprodução;
- Qualidade perceptual MOS (Mean Opinion Score) comparativa;
- Comportamento em velocidades diferentes (0.75x, 1.0x, 1.5x, 2.0x).

## Corpus

- EPUB curto para smoke test;
- EPUB médio para leitura de capítulo;
- EPUB grande do usuário para estresse de memória;
- Frases controladas para fonética, acentos, siglas e numerais romanos.

## Entregáveis

- Relatório CSV/JSON bruto de telemetria;
- Tabelas e gráficos comparativos para a monografia;
- Roteiro reproduzível de teste;
- Descrição do aparelho e ambiente (Motorola G85 & Windows x64);
- Análise estatística dos resultados para a monografia do TCC.
