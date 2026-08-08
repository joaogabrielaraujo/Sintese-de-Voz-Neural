---
phase: 16-telemetria-tcc
plan: 01
type: execute
wave: 1
depends_on: [15]
autonomous: false
---

# Plano 16 — Coletar métricas no aparelho real e Windows

## Tarefas

1. Criar um modo de benchmark que registre eventos sem alterar o fluxo normal do Reader.
2. Registrar timestamp de seleção, início da segmentação, início da primeira inferência, áudio disponível, reprodução e conclusão.
3. Medir tamanho da fila, quantidade de itens sintetizados, memória alocada e liberada e erros (comparando Piper VITS vs Supertonic 3).
4. Executar cada corpus em pelo menos três repetições por velocidade.
5. Exportar dados para análise e gerar tabelas comparáveis.
6. Separar resultados de Windows e Android, sem misturar hardware.
7. Registrar avaliações MOS e associá-las às frases/condições testadas.

## Critério de aceite

Os dados permitem afirmar, com aparelho e versão do modelo identificados, se a pipeline acompanha a reprodução e qual é o custo de memória, CPU e latência em livros de tamanhos diferentes.
