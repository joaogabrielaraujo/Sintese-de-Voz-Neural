---
phase: 14
slug: ui-redesign
status: approved
shadcn_initialized: false
preset: none
created: 2026-08-03
updated: 2026-08-03
visual_source: vozlume_redesign.html
implementation: native-flutter
---

# Fase 14 — Contrato de UI

> Contrato visual e de interação para o redesign editorial e o leitor responsivo em Android e Windows. Gerado por `gsd-ui-researcher`; a aprovação cabe ao `gsd-ui-checker`.

---

## Fonte de verdade e limites

- `vozlume_redesign.html` é a fonte de verdade para identidade editorial, composição, hierarquia, temas, cores, tipografia e microcopy. Esta decisão substitui referências anteriores a `design_mockup.html`. **Fonte: decisão do usuário.**
- O HTML é somente referência visual. A implementação deve ser reconstruída com widgets Flutter nativos; é proibido usar `WebView`, `HtmlElementView`, renderizador web embutido ou carregar esse arquivo em runtime. **Fonte: decisão do usuário.**
- A interface deve preservar biblioteca, busca, ajustes, importação, leitor sincronizado, player, RTF, MOS, fila, memória e estados da engine sem alterar o pipeline offline. **Fonte: CONTEXT.md e ROADMAP.md.**
- Fontes, ícones e demais assets devem ser empacotados no aplicativo. Nenhum recurso visual ou tipográfico pode depender de rede em runtime. **Fonte: CONTEXT.md e RNF-01.**

---

## Design System

| Propriedade | Valor |
|---|---|
| Ferramenta | Flutter Material 3, tematizado por tokens próprios |
| Preset | não aplicável |
| Biblioteca de componentes | widgets Flutter nativos; nenhum kit web |
| Ícones | Material Symbols/Icons incluídos no bundle; traço simples e sem ícones decorativos de terceiros |
| Fontes | Spectral (leitura e títulos editoriais), Archivo (interface), Space Mono (estado e informação técnica) |
| Temas | claro e escuro, com paridade funcional e semântica |

As famílias Spectral, Archivo e Space Mono devem ser declaradas em `pubspec.yaml` com arquivos locais e usadas pelos nomes exatos no `ThemeData`. Fallbacks locais são apenas contingência: Georgia para Spectral, Segoe UI/Roboto para Archivo e Consolas para Space Mono.

---

## Spacing Scale

Valores declarados; todo espaçamento de layout deve usar somente esta escala:

| Token | Valor | Uso |
|---|---:|---|
| xs | 4px | separação de ícone e texto, ajustes inline |
| sm | 8px | controles compactos e lacunas internas |
| md | 16px | padding padrão e distância entre elementos |
| lg | 24px | padding de seções e leitor |
| xl | 32px | lacunas de layout e blocos principais |
| 2xl | 48px | separação entre regiões de página |
| 3xl | 64px | respiro de desktop e grandes transições |

Exceção: controles interativos devem ter alvo mínimo de `44×44px`, inclusive ícones, scrubber e itens de navegação. Linhas de `1px` e indicadores de progresso de `2px` são espessuras visuais, não espaçamento.

---

## Typography

O contrato usa exatamente quatro tamanhos e dois pesos (`400` e `600`). Não introduzir tamanhos ou pesos intermediários por widget.

| Papel | Família | Tamanho | Peso | Altura de linha |
|---|---|---:|---:|---:|
| Status/legenda técnica | Space Mono | 12px | 400 | 1.4 |
| Corpo de interface e leitura | Archivo para UI; Spectral para texto do EPUB | 16px | 400 | 1.5 na UI; 1.7 na leitura |
| Título editorial/seção | Spectral | 20px | 600 | 1.2 |
| Marca/display | Spectral | 28px | 600 | 1.2 |

- Títulos de livro, capítulo e seção editorial usam Spectral; rótulos, botões, campos e navegação usam Archivo; RTF, MOS, contadores, tempo, progresso, engine e mensagens de estado usam Space Mono.
- Texto do EPUB deve respeitar escala de texto do sistema até `200%`, com reflow, sem corte vertical e sem reduzir a fonte para caber.
- Títulos longos podem ocupar duas linhas; rótulos de navegação e chips usam elipse após uma linha somente quando o layout não puder refluí-los.

---

## Color

### Tema claro

| Papel | Valor | Uso |
|---|---|---|
| Dominante (60%) | `#E7DFC6` papel | fundo, página de leitura, áreas de maior permanência |
| Secundária (30%) | `#DED2AE` papel-cartão; elevada `#D6C99E` | cards, navegação, player e superfícies elevadas |
| Acento (10%) | `#2E5578` sinal; variação `#3F6788` | CTA, seleção, foco, navegação ativa e play/pause |
| Grifo editorial | `#A8402C` | frase ativa, progresso de leitura e marcações editoriais, nunca estado genérico de erro |
| Positivo/offline | `#4B5D3A` musgo | offline, engine pronta e sucesso |
| Texto | `#242229`; suave `#6B6355`; fraco `#948C78` | hierarquia de conteúdo |
| Linha | `rgba(36,34,41,0.16)` | divisores e contornos |
| Destrutivo | `#8C2F2F` | excluir livro e falha irreversível apenas |

### Tema escuro

| Papel | Valor | Uso |
|---|---|---|
| Dominante (60%) | `#262A22` ardósia | fundo e página de leitura |
| Secundária (30%) | `#2E332A`; elevada `#363C31` | cards, navegação, player e superfícies elevadas |
| Acento (10%) | `#6E9BC1`; variação `#82ABD1` | os mesmos elementos reservados do tema claro |
| Grifo editorial | `#C25A42` | frase ativa, progresso e marcações editoriais |
| Positivo/offline | `#93AC72` | offline, engine pronta e sucesso |
| Texto | `#E9E2C9`; suave `#B3AC94`; fraco `#83806C` | hierarquia de conteúdo |
| Linha | `rgba(233,226,201,0.14)` | divisores e contornos |
| Destrutivo | `#FFB4AB` | excluir livro e falha irreversível apenas |

Acento reservado para: botão primário de importação, play/pause, item de navegação selecionado, foco de teclado, seleção pendente e links acionáveis. O grifo é reservado para a frase em reprodução e progresso editorial. Cor nunca pode ser o único sinal: combinar com ícone, texto, sublinhado, colchetes ou borda.

O seletor em Ajustes deve oferecer `Sistema`, `Claro` e `Escuro`, iniciar em `Sistema` e persistir localmente a escolha. Trocar o tema não altera posição de leitura, reprodução nem foco.

---

## Copywriting Contract

| Elemento | Texto |
|---|---|
| CTA primário | `Importar EPUB` |
| Apoio do CTA | `O arquivo permanece somente neste dispositivo.` |
| Estado vazio — título | `Sua biblioteca ainda está vazia.` |
| Estado vazio — corpo | `Importe um EPUB para começar a ler e ouvir offline.` |
| Busca vazia | `Nenhum livro corresponde à busca.` |
| Importação em curso | `Importando EPUB…` |
| Importação concluída | `EPUB importado com sucesso.` |
| Extensão de importação inválida | `Este arquivo não é um EPUB. Escolha um arquivo com a extensão .epub.` Ação: `Escolher outro arquivo`. |
| EPUB inválido | `Não foi possível ler este EPUB. O arquivo pode estar incompleto ou corrompido.` Ação: `Escolher outro arquivo`. |
| Erro de importação | `Não foi possível importar este EPUB. O arquivo anterior e sua biblioteca não foram alterados.` Ação: `Tentar importar novamente`. |
| Conteúdo vazio | `Este capítulo não contém texto para leitura.` |
| Engine indisponível | `A voz offline está indisponível. Revise o modelo de voz antes de continuar.` Ação: `Abrir Ajustes`. |
| Erro do leitor | `Não foi possível abrir este capítulo. O livro e sua posição de leitura continuam salvos.` Ação: `Tentar abrir capítulo novamente`. |
| Erro de reprodução | `Não foi possível reproduzir este trecho. Sua posição de leitura foi mantida.` Ação primária: `Tentar reproduzir novamente`. Se a falha persistir, ação secundária: `Abrir Ajustes`. |
| Relatório indisponível | `Não foi possível carregar o relatório de métricas agora. A leitura e a reprodução continuam disponíveis.` Ação: `Tentar carregar relatório novamente`. |
| Confirmação destrutiva | `Excluir livro?` — `A cópia salva e o progresso serão removidos deste dispositivo. O arquivo original não será alterado.` Botões: `Manter livro` e `Excluir livro`. |

Mensagens devem explicar problema e próximo passo em português do Brasil. Não expor exceções, caminhos internos ou códigos técnicos como mensagem principal; estes podem aparecer em uma área técnica expansível.

---

## Contrato de composição

### Biblioteca

- **Elemento focal primário:** o card `Importar EPUB`, com borda tracejada e ícone de adição; a lista `Continuar lendo` é o segundo nível da hierarquia visual.
- Cabeçalho com marca `VozLume`, subtítulo `Leitor neural de EPUB`, badge offline em musgo e chip da engine em sinal.
- Card de importação com borda tracejada, ícone de adição, CTA e texto de privacidade. Durante importação, desabilitar novo acionamento, manter dimensão, mostrar progresso e anunciar o estado em região semântica viva.
- Seção `Continuar lendo` com cards de livro: marca de capa ou capa real, número de catálogo, título, autor, regra de progresso, porcentagem em carimbo e menu contextual.
- Cards têm toda a área clicável; menu contextual não pode disparar abertura do livro. Exclusão exige o diálogo definido no contrato de copywriting.
- A tela inicial não mostra frases ou capítulos de demonstração. Seletor de capítulo e controles TTS existem somente após abrir um livro.

### Leitor

- **Elemento focal primário:** a coluna contínua do capítulo, com a frase ativa marcada pelo sublinhado ondulado em grifo; cabeçalho e player permanecem visualmente subordinados ao texto.
- Cabeçalho com voltar, título do livro e subtítulo contextual; abaixo, seletor de capítulo e contagem de palavras.
- O capítulo é uma coluna textual contínua, sem cards por frase. Imagens EPUB aparecem na posição original, ajustadas à largura e preservando proporção; alt text e imagens não entram no pipeline TTS, conforme RF-07.
- Frase ativa usa texto normal, peso `600` e sublinhado ondulado na cor grifo. Seleção pendente usa colchetes/borda tracejada na cor sinal e exige confirmação antes de deslocar a reprodução.
- O scroll acompanha a frase ativa apenas quando ela sai da área visível; nunca reposiciona continuamente enquanto a pessoa está rolando manualmente. Após interação manual, suspender auto-scroll até a próxima mudança de frase ou comando explícito.
- A confirmação de retomada mostra frase escolhida e ações `Manter posição atual` e `Retomar daqui`, sem cobrir o texto selecionado em telas largas; no telefone pode usar bottom sheet.

### Player e telemetria

- Player persistente contém estado da síntese, contador de frase, RTF quando disponível, tempo atual/total, scrubber, velocidade, parar, play/pause e acesso a MOS.
- Em telefone e tablet, fica ancorado ao rodapé e respeita safe areas; no desktop, fica em painel lateral/inferior flexível sem reduzir a coluna de leitura abaixo do mínimo útil.
- Estados ausentes mostram `—` em métricas, nunca `0` inventado. RTF, MOS, fila e memória ficam em painel técnico recolhível e permanecem alcançáveis por teclado e toque.
- O scrubber aceita toque, arraste, mouse e setas quando focado. Play/pause mantém a mesma posição e rótulo semântico coerente com o estado atual.

---

## Responsividade e entrada

| Faixa | Navegação | Composição |
|---|---|---|
| Telefone `<600px` | barra inferior compacta | coluna única; padding lateral 16; player no rodapé; diálogos densos como bottom sheet quando necessário |
| Tablet `600–899px` | barra inferior, conforme decisão da fase | coluna central fluida; cards podem formar grade somente se cada card mantiver leitura confortável; player no rodapé com controles em `Wrap` |
| Desktop `≥900px` | `NavigationRail` lateral | conteúdo centralizado; leitor e painel do player usam `Expanded`/`Flexible`; mouse e teclado completos |

- A troca obrigatória é barra inferior abaixo de `900px` e `NavigationRail` a partir de `900px`. **Fonte: STATE.md.**
- Biblioteca usa largura fluida com máximo de `960px`; coluna de leitura usa largura fluida com máximo de `760px`. Esses valores são limites de legibilidade, não largura fixa.
- Usar `LayoutBuilder`, `MediaQuery`, `Expanded`, `Flexible`, `Wrap`, `ConstrainedBox` e safe areas. Proibidos frames de telefone, `SizedBox` de largura de tela fixa, altura fixa de leitor e posicionamento absoluto que cause overflow.
- Toda tela deve funcionar em 320px de largura, orientação retrato/paisagem, tablet e janela Windows redimensionável. Em alturas pequenas, conteúdo e controles rolam ou refluem; nunca ficam inacessíveis.
- Atalhos: `Space` play/pause; `Escape` fecha diálogo/seleção pendente ou volta; `←/→` percorrem frases quando o foco está no leitor; `Ctrl+O` abre importação no Windows. Nenhum atalho deve capturar digitação em campo de texto.
- Ordem de foco segue navegação → conteúdo → player. Indicador de foco usa cor sinal com contorno visível de pelo menos `2px`. Mouse, toque, teclado e acessibilidade disparam o mesmo modelo de ações.

---

## Estados obrigatórios

| Superfície | Estados e comportamento |
|---|---|
| Biblioteca | vazia; um livro; muitos livros; busca vazia; título/autor longos; lista rolável |
| Importação | ociosa; escolhendo arquivo; processando; cancelada; extensão inválida; EPUB inválido; concluída; erro recuperável |
| Engine | inicializando; pronta; auto-failover; indisponível |
| Leitor | carregando; capítulo vazio; conteúdo parcial; texto e imagem; frase ativa; seleção pendente; fim do capítulo; erro |
| Reprodução | parada; sintetizando; reproduzindo; pausada; buscando posição; concluída; erro |
| Métricas | ausentes; coletando; disponíveis; MOS não avaliado; MOS salvo; relatório indisponível |
| Tema/layout | claro; escuro; contraste do sistema; telefone; tablet; desktop; texto ampliado; janela baixa |

---

## UI Considerations

Sondagem pós-verificação: **32 combinações elemento/estado resolvidas em 8 categorias; 8 cobertas, 0 backstop, 0 não resolvidas**.

| Categoria | Elemento(s) | Status | Resolução / motivo |
|---|---|---|---|
| empty | biblioteca, leitor, métricas, ajustes/tema | ✅ covered | Renderizar os textos vazios deste contrato; métricas ausentes usam `—` e não valores inventados. |
| loading | biblioteca, leitor, player, métricas, ajustes/tema | ✅ covered | Preservar geometria, desabilitar repetição da ação, mostrar indicador local e anunciar mudança semântica. |
| error | biblioteca, leitor, player, métricas, ajustes/tema | ✅ covered | Mostrar problema, ação recuperável e fallback parcial; preservar livro e progresso anteriores. |
| populated | biblioteca, leitor, métricas | ✅ covered | Cards editoriais, texto contínuo e controles persistentes seguem as composições declaradas. |
| partial | biblioteca, métricas, ajustes/tema | ✅ covered | Renderizar blocos válidos e imagens disponíveis; omitir campos ausentes sem quebrar o fluxo; mostrar métricas disponíveis individualmente. |
| overflow | biblioteca, leitor, player, métricas, ajustes/tema | ✅ covered | Reflow/scroll primeiro; duas linhas para títulos; elipse só em metadados; controles usam `Wrap`; texto de leitura nunca é truncado. |
| zero-one-many | biblioteca, métricas | ✅ covered | Zero usa estado vazio, um usa card completo sem grade artificial e muitos usam lista/grade rolável responsiva. |
| long-text | biblioteca, leitor, player, métricas, ajustes/tema | ✅ covered | Títulos refluem em até duas linhas; status técnico usa elipse com tooltip e semântica; conteúdo EPUB reflowa integralmente. |

---

## Acessibilidade e verificação visual

- Contraste mínimo: `4.5:1` para texto normal e `3:1` para texto grande, ícones essenciais, foco e limites de controles. Validar ambos os temas com os pares reais, não apenas tokens isolados.
- Todo controle de ícone tem tooltip e rótulo semântico em pt-BR. Estados offline, erro, reprodução e seleção não dependem apenas de cor.
- Respeitar `MediaQuery.disableAnimations`/movimento reduzido; transições de tema e layout não excedem 200ms e não animam o scroll automaticamente quando movimento reduzido estiver ativo.
- Testes de widget/golden devem cobrir 390×844, 800×1280 e 1440×900 nos temas claro e escuro, além de texto a 200%, janela de 320px, títulos longos, listas vazias e controles do player em overflow.
- Critério de fidelidade: comparar biblioteca e leitor Flutter lado a lado com `vozlume_redesign.html`, conferindo hierarquia, proporções flexíveis, paleta, tipografia, bordas tracejadas, carimbo de progresso, grifo da frase e densidade do player; não reproduzir moldura de browser ou medidas fixas do mockup.

---

## Registry Safety

| Registry | Blocos usados | Safety Gate |
|---|---|---|
| shadcn official | nenhum | não aplicável — projeto Flutter |
| terceiros | nenhum | não aplicável — widgets Flutter nativos e assets locais |

---

## Checker Sign-Off

- [x] Dimensão 1 Copywriting: PASS
- [x] Dimensão 2 Visuals: PASS
- [x] Dimensão 3 Color: PASS
- [x] Dimensão 4 Typography: PASS
- [x] Dimensão 5 Spacing: PASS
- [x] Dimensão 6 Registry Safety: PASS

**Aprovação:** UI-SPEC VERIFIED — 2026-08-03
