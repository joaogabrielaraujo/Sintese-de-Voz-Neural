# Projeto TCC: Síntese de Voz Neural Offline em Dispositivos Móveis

## Visão Geral do Projeto
- **Aluno**: João Gabriel Araújo Almeida (Matrícula: 22111215)
- **Orientador**: Matheus Giovanni
- **Instituição**: Colegiado do Curso de Engenharia de Computação (UEFS)
- **Título**: Síntese de Voz Neural Offline em Dispositivos Móveis: Arquitetura e Implementação de um Leitor de EPUBs Baseado em Edge Computing
- **Palavras-chave**: Edge Computing; Text-to-Speech (TTS); Inferência Local; VITS; ONNX; EPUB; PLN.

---

## Escopo e Arquitetura Proposta

### 1. Desafio Tecnológico
Equilibrar inferência de Deep Learning de alta qualidade (VITS ONNX) localmente em dispositivos móveis (Edge Computing) com restrições de memória RAM, CPU e bateria, evitando vazamentos de memória (OOM) na leitura de textos longos de livros digitais (EPUB).

### 2. Documentação Técnica da Inferência ONNX & Resolução de Falhas
- 📘 [ONNX_TTS_TECHNICAL_GUIDE.md](file:///C:/Users/55759/Documents/sintese_de_voz/.planning/ONNX_TTS_TECHNICAL_GUIDE.md): Guia detalhado contendo o diagnóstico técnico dos problemas do motor neural (espeak-ng-data, FFI DLLs, provedores) e a solução de resiliência baseada na análise do VoxSherpa-TTS.

### 3. Componentes da Arquitetura
1. **Módulo de Extração EPUB**: Leitura estruturada de arquivos HTML/XHTML em contêineres EPUB.
2. **Pipeline PLN / TTS-Norm**: Normalização de texto (numerais, siglas, pontuações, caracteres especiais para texto por extenso).
3. **Fatiador de Sentenças & Buffer Circular (FIFO)**: Fragmentação de texto contínuo e gerenciamento assíncrono de memória para produção/consumo de áudio sem travamentos ou estouro de RAM.
4. **Motor de Inferência Neural Offline**: Integração com motor de inferência móvel (Sherpa-onnx / Piper TTS) executando modelos VITS otimizados para ONNX.
5. **Módulo de Expressividade & Pausas (`PunctuationPauseHelper`)**: Injeção de silêncios por pontuação com jitter estocástico (±10%) inspirado no VoxSherpa-TTS.
6. **Módulo de Telemetria e Benchmark**: Medição de Real-Time Factor (RTF), consumo de RAM e perfil de uso de CPU.

---

## O que a IA (Antigravity) consegue fazer vs. O que depende do Usuário

### ✅ O que DÁ para fazer autonomamente no ambiente de dev:
1. **Arquitetura de Software completa**: Estruturar o projeto, modularização e design patterns (Buffer Circular, Producer-Consumer, Threads assíncronas).
2. **Pipeline de Normalização de Texto (PLN/TTS-Norm em PT-BR)**: Algoritmo de tratamento de numerais, ordenais, siglas, abreviações e limpeza de tags EPUB/HTML.
3. **Integração do Motor de Inferência ONNX**: Wrappers/bindings para Sherpa-onnx/Piper TTS, carregamento do modelo VITS `pt_BR` e testes de geração de voz.
4. **Gerenciador de Buffer Assíncrono**: Fila concorrente com descarte de chunks processados para mitigar OOM.
5. **Scripts de Benchmark & Telemetria**: Medição de RTF, taxa de throughput e consumo de memória baseline no ambiente desktop/CLI.
6. **Redação do Documento do TCC**: Rascunho estruturado dos capítulos (Introdução, Fundamentação Teórica, Metodologia, Arquitetura, Resultados e Conclusão).

### ❌ O que NÃO TEM COMO a IA fazer sozinha:
1. **Medição de Bateria e Térmica em Hardware Físico Real**: Coleta de gasto de bateria de smartphone físico (requer o app rodando no dispositivo Android/iOS do aluno).
2. **Treinamento de Modelo VITS do Zero**: Treinar modelos de voz exige datasets massivos e GPUs dedicadas; o escopo correto do TCC é utilizar modelos pré-treinados exportados para ONNX.
3. **Assinaturas e Processos Acadêmicos**: Assinaturas de orientador/coordenador e apresentação presencial da banca.
