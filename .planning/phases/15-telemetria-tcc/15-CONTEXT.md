---
phase: 15-telemetria-tcc
status: planned
depends_on: [14]
---

# Fase 15 — Telemetria e avaliação quantitativa para o TCC

## Objetivo

Medir o comportamento do sistema em aparelho real após o release candidate estar estável.

## Dimensões

- latência até o primeiro áudio;
- pausa entre frases;
- RTF por frase e capítulo;
- RAM mínima, média e pico;
- CPU durante síntese e reprodução;
- bateria e temperatura em sessões longas;
- falhas de importação, engine e reprodução;
- qualidade perceptual MOS;
- comportamento em velocidades diferentes.

## Corpus

- EPUB curto para smoke test;
- EPUB médio para leitura de capítulo;
- EPUB grande do usuário para estresse;
- frases controladas para fonética, acentos, siglas e numerais romanos.

## Entregáveis

- relatório CSV/JSON bruto;
- tabelas e gráficos;
- roteiro reproduzível de teste;
- descrição do aparelho e ambiente;
- análise dos resultados para a monografia.
