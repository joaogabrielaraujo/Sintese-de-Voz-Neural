# UI-SPEC — Fase 14: Redesign da UI e Leitor Responsivo

## Direção visual

Interface editorial escura, silenciosa e focada na leitura. O conteúdo textual é o elemento principal; a síntese aparece como uma camada de estado e controle, sem transformar cada frase em um cartão.

## Tokens

| Token | Valor | Uso |
|---|---|---|
| ink | `#12151C` | fundo principal |
| ink-2 | `#1B1F29` | cards e superfícies |
| ink-3 | `#242938` | confirmação e superfície elevada |
| paper | `#EDE7D6` | texto principal |
| paper-dim | `#9CA0AC` | texto secundário |
| paper-faint | `#5C6072` | metadados |
| amber | `#E3A452` | voz, ação primária e frase ativa |
| teal | `#4FA9A6` | offline, engine ativa e estado positivo |
| coral | `#E2694F` | erro e alerta |
| line | `#2B303F` | divisores e bordas |

## Tipografia

- Texto de leitura e títulos de capítulo: Literata, tamanho base 16–18, altura 1.65–1.75.
- Interface e controles: Manrope, tamanhos 12–16.
- Métricas, RTF, estado da engine e contadores: JetBrains Mono, tamanhos 10–12.
- As fontes devem ser empacotadas no app ou substituídas por fallbacks locais; não usar `@import` remoto.

## Superfícies e componentes

### Biblioteca

- Cabeçalho com nome do produto e badge `OFFLINE`.
- Card tracejado de importação com ação clara `Importar EPUB`.
- Chip da engine com indicação visual de sinal/forma de onda.
- Lista de livros com capa, título, autor, progresso e capítulo atual.
- A Home não renderiza texto fragmentado nem capítulos de demonstração; o conteúdo textual pertence exclusivamente ao leitor.
- O seletor de capítulo e os controles de síntese aparecem somente depois de abrir um EPUB, na tela de leitura.
- Android: navegação inferior para Biblioteca, Buscar e Ajustes.
- Windows: `NavigationRail` ou painel lateral equivalente; a lista deve permanecer visível em janelas largas.

### Leitor

- Cabeçalho com voltar, título do livro e capítulo selecionado.
- Texto contínuo em coluna de leitura limitada; não usar cards por frase.
- Frase ativa: texto `paper`, sublinhado/faixa âmbar e peso maior.
- Frase selecionada: sublinhado tracejado teal.
- Confirmação de retomada: superfície `ink-3`, ação secundária contornada e ação primária âmbar.
- Player fixo ao final no Android e ancorado no painel inferior/lateral no Windows.
- Player deve expor play/pause, parada, avanço/retrocesso quando aplicável, velocidade, scrubber, frase atual e RTF.

## Responsividade

- Breakpoint compacto: largura menor que 700 px; layout vertical, controles com alvo mínimo de 44 px.
- Breakpoint largo: largura a partir de 900 px; navegação lateral e painel de leitura centralizado.
- Entre os breakpoints, usar `LayoutBuilder`, evitando tamanhos fixos de telefone.
- Texto nunca deve ocupar toda a largura de uma janela Windows; usar largura máxima confortável.
- Teclado: `Space` play/pause, `Escape` cancelar seleção/voltar, setas para navegação quando o foco estiver no leitor.
- Mouse e toque devem disparar o mesmo modelo de interação.

## Estados obrigatórios

- Livro vazio e biblioteca sem itens.
- Importação em andamento, cancelada, inválida e concluída.
- Engine inicializando, ativa, em failover e indisponível.
- Síntese parada, processando, reproduzindo, pausada, concluída e com erro.
- Frase ativa, frase selecionada e confirmação pendente.
- Métricas ausentes, disponíveis e relatório MOS salvo.

## Critérios de aceitação

1. O redesign funciona sem rede em Android e Windows.
2. Importar EPUB, selecionar capítulo, iniciar síntese e reproduzir áudio continuam funcionando.
3. RTF, MOS, status da engine, fila e memória permanecem acessíveis sem poluir a leitura.
4. A frase ativa permanece sincronizada com a reprodução.
5. A interface permanece utilizável com toque, mouse e teclado.
6. Testes de widget cobrem pelo menos biblioteca, leitor, estados de importação e player responsivo.
