---
phase: 14-ui-redesign
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
---

# Plano 14 — Implementar UI responsiva baseada no mockup

## Objetivo

Extrair o tema e os componentes visuais para uma UI Flutter responsiva, substituindo o layout monolítico atual sem alterar os serviços de síntese e reprodução.

## Tarefas

1. Criar tokens/theme compartilhados para cores, tipografia, espaçamentos, raios e estados.
2. Separar biblioteca, leitor e navegação em widgets testáveis.
3. Implementar layout compacto Android e layout largo Windows com `LayoutBuilder`.
4. Adaptar texto contínuo, destaque de frase, confirmação de seleção e player aos tokens do mockup.
5. Preservar os callbacks e estados atuais de EPUB, engine, pipeline, áudio, MOS e métricas.
6. Adicionar estados vazios, erro, processamento e acessibilidade de toque/teclado.
7. Atualizar testes de widget e executar análise/testes Flutter em pelo menos uma configuração disponível.

## Critério de aceite

O aplicativo apresenta a linguagem visual do mockup em Android e Windows, mantém os fluxos funcionais existentes e passa pelos testes de widget e análise estática relevantes.
