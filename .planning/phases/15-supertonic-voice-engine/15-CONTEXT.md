---
phase: 15-supertonic-voice-engine
status: planned
depends_on: [14]
---

# Fase 15 — Integração do Motor de Voz Neural Expressivo Supertonic 3

## Objetivo

Integrar o modelo neural de síntese vocal **Supertonic 3** (e/ou arquiteturas ONNX de nova geração) ao orquestrador `CompositeTTSEngine`, eliminando o aspecto robótico dos modelos VITS tradicionais e proporcionando uma experiência de leitura imersiva e natural em e-books EPUB.

## Dimensões

- **Download & Carregamento ONNX:** Suporte ao modelo quantizado `supertonic-3` (int8/fp16) via ONNX Runtime / `sherpa-onnx`.
- **Tokenização & Prosódia:** Pipeline de tokenização neural ONNX para tratamento de acentuação, pontuação e entonação fluida.
- **Arquitetura Strategy (`SupertonicOnnxEngine`):** Implementação da interface `ITTSEngine` perfeitamente isolada no ecossistema Flutter/C++.
- **Seletor Multi-Motor na UI:** Opção no painel de configurações para o usuário escolher entre *Piper VITS (Padrão)*, *Supertonic 3 (Expressivo Neural)* ou *Voz Nativa do Sistema*.
- **Resiliência & Fallback:** Se houver falha de memória RAM ou incompatibilidade de instrução no hardware, o `CompositeTTSEngine` realiza o fallback transparente para o motor secundário sem travar a aplicação.
- **Validação de Performance:** Medição de latência (RTF) e memória RAM no Motorola G85 (Android) e Windows x64.

## Corpus & Testes

- Frases de validação prosódica (perguntas `?`, exclamações `!`, pausas `,` e pontuação complexa).
- Capítulos de livros EPUB reais para validação de leitura contínua.
- Comparativo perceptual de áudio (MOS) entre Piper VITS e Supertonic 3.

## Entregáveis

- Classe `SupertonicOnnxEngine` implementando `ITTSEngine`.
- Atualização do `CompositeTTSEngine` e seletor de voz na interface do aplicativo.
- Testes unitários e de integração validando a geração de PCM e controle de ciclo de vida.
- Modelo ONNX quantizado integrado à pasta de assets ou mecanismo de download sob demanda.
