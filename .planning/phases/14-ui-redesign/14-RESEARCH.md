# Fase 14: Redesign da UI e Leitor Responsivo Android/Windows â€” Pesquisa

**Pesquisado em:** 2026-08-03  
**DomÃ­nio:** Flutter Material 3 nativo, UI editorial adaptativa, acessibilidade e validaÃ§Ã£o visual  
**ConfianÃ§a:** ALTA para o diagnÃ³stico do repositÃ³rio e o contrato; MÃ‰DIA para padrÃµes externos consultados por documentaÃ§Ã£o oficial via WebSearch

<user_constraints>
## RestriÃ§Ãµes do UsuÃ¡rio (de CONTEXT.md)

### DecisÃµes Bloqueadas

- O mockup Ã© referÃªncia visual; nÃ£o serÃ¡ embutido como HTML.
- Android prioriza leitura vertical, controles acessÃ­veis ao toque e navegaÃ§Ã£o inferior.
- Windows usa layout largo com navegaÃ§Ã£o lateral, mouse, teclado e conteÃºdo centralizado.
- O redesign nÃ£o altera o pipeline de sÃ­ntese, importaÃ§Ã£o, fila, memÃ³ria, RTF ou MOS.
- Fontes externas nÃ£o serÃ£o carregadas pela rede em runtime; usar fontes empacotadas ou fallbacks locais.

### the agent's Discretion

Nenhuma seÃ§Ã£o `## o agente's Discretion` existe em `14-CONTEXT.md`.

### Deferred Ideas (OUT OF SCOPE)

Nenhuma seÃ§Ã£o `## Deferred Ideas` existe em `14-CONTEXT.md`. A paginaÃ§Ã£o por pÃ¡gina original estÃ¡ explicitamente adiada em `STATE.md` e nos planos existentes; preservar leitura contÃ­nua. [VERIFIED: .planning/STATE.md:29-33]
</user_constraints>

## Resumo

O plano executado `14-PLAN.md` entregou separaÃ§Ã£o inicial de widgets e o breakpoint estrutural correto, mas nÃ£o implementou o contrato visual aprovado. O cÃ³digo atual ainda declara somente tema escuro, usa as famÃ­lias `"Literata"`, `"Manrope"` e `"JetBrains Mono"`, e contÃ©m a paleta antiga `ink/amber/teal`; o contrato exige exatamente `"Spectral"`, `"Archivo"`, `"Space Mono"`, temas claro/escuro e os tokens papel/sinal/grifo/musgo. CitaÃ§Ã£o verificÃ¡vel do cÃ³digo atual: `fontFamily: 'Literata'`, `fontFamily: 'JetBrains Mono'`, `fontFamily: 'Manrope'` e apenas `static ThemeData dark()`. [VERIFIED: lib/ui/app_theme.dart:39-65] O `pubspec.yaml` nÃ£o contÃ©m uma seÃ§Ã£o `fonts:`; apÃ³s `uses-material-design: true` ele declara diretamente `assets:`. [VERIFIED: pubspec.yaml:26-30]

O shell adaptativo jÃ¡ preserva a decisÃ£o essencial: `AppDestination { library, search, settings }`, `AppBreakpoints.wide = 900.0`, `NavigationRail` para `maxWidth >= wide` e `NavigationBar` abaixo disso. Esses valores verbatim sÃ£o a base correta e devem ser mantidos. [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:5-35] [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:37-80] [VERIFIED: lib/ui/app_theme.dart:34-37] PorÃ©m biblioteca, leitor, player, ajustes, estados e testes ainda divergem amplamente da UI-SPEC: nÃ£o hÃ¡ preferÃªncia de tema, fontes locais, auto-scroll da frase ativa, painel tÃ©cnico recolhÃ­vel, safe areas explÃ­citas, `Ctrl+O`, ordem de foco, goldens ou cobertura a 200% de texto. [VERIFIED: lib/main.dart:32-43] [VERIFIED: lib/ui/widgets/settings_view.dart:6-87] [VERIFIED: lib/ui/widgets/reader_document_view.dart:31-129] [VERIFIED: test/ui/redesign_widgets_test.dart:14-218]

Os planos 14-02 a 14-06 tratam principalmente durabilidade, concorrÃªncia e telemetria; sÃ£o necessÃ¡rios para preservar verdade funcional, mas nÃ£o substituem a implementaÃ§Ã£o do UI-SPEC. O planejador deve reabrir a entrega visual como um plano corretivo de fundaÃ§Ã£o antes das alteraÃ§Ãµes de biblioteca/leitor e ampliar 14-04, 14-06 e 14-07 para os contratos visuais correspondentes. [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] [VERIFIED: .planning/phases/14-ui-redesign/14-07-PLAN.md]

**RecomendaÃ§Ã£o principal:** criar primeiro a fundaÃ§Ã£o de design nativa (assets tipogrÃ¡ficos, tokens semÃ¢nticos, temas e preferÃªncia persistida), depois aplicar esses contratos Ã  biblioteca/ajustes e ao leitor/player, e sÃ³ entÃ£o fechar com a matriz widget/golden/acessibilidade e UAT Android/Windows. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-39] [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

## Mapa de Responsabilidade Arquitetural

| Capacidade | Tier primÃ¡rio | Tier secundÃ¡rio | RazÃ£o |
|---|---|---|---|
| Tokens, tipografia, tema e movimento reduzido | Browser / Client (Flutter UI) | Storage local | `ThemeData`, `MediaQuery` e preferÃªncia de tema pertencem Ã  apresentaÃ§Ã£o; somente a escolha persistida cruza para storage. [CITED: https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html] |
| Shell Biblioteca/Busca/Ajustes | Browser / Client (Flutter UI) | â€” | O cÃ³digo jÃ¡ concentra a troca `NavigationBar`/`NavigationRail` no shell de widgets. [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:37-80] |
| Biblioteca editorial e estados de importaÃ§Ã£o | Browser / Client (Flutter UI) | API/Backend local | Widgets apresentam estado e disparam callbacks; importador e repositÃ³rio continuam fora da camada visual. [VERIFIED: lib/ui/widgets/library_view.dart:6-32] [VERIFIED: lib/main.dart:840-863] |
| Leitor sincronizado e auto-scroll | Browser / Client (Flutter UI) | API/Backend local | O widget renderiza frases/blocos e recebe Ã­ndices/callbacks; pipeline continua proprietÃ¡rio da sÃ­ntese. [VERIFIED: lib/ui/widgets/reader_document_view.dart:11-25] [VERIFIED: lib/ui/widgets/reader_page.dart:11-61] |
| Player persistente e telemetria recolhÃ­vel | Browser / Client (Flutter UI) | API/Backend local | Controles e mÃ©tricas sÃ£o apresentaÃ§Ã£o de `IAudioPlayerService`/estado do pipeline, sem reter PCM na UI. [VERIFIED: lib/ui/widgets/audio_player_control_bar.dart:6-30] [VERIFIED: .planning/phases/14-ui-redesign/14-06-PLAN.md] |
| EPUB, fila, memÃ³ria, RTF e MOS | API/Backend local | Storage local | CONTEXT proÃ­be mudar essas fronteiras; os planos 14-02â€“14-06 fecham consistÃªncia e telemetria sem alterar o princÃ­pio offline. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |

## Auditoria do Estado Atual contra a UI-SPEC

| Contrato | Estado atual | Trabalho obrigatÃ³rio |
|---|---|---|
| Flutter nativo, sem HTML | Cumprido: nÃ£o hÃ¡ `WebView` no cÃ³digo pesquisado; UI Ã© composta por widgets Flutter. [VERIFIED: codebase audit via `rg` e .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] | Manter a proibiÃ§Ã£o e nunca adicionar o HTML aos assets de runtime. |
| Breakpoint de navegaÃ§Ã£o 900 px | Cumprido: valor verbatim `wide = 900.0`; rail acima e barra abaixo. [VERIFIED: lib/ui/app_theme.dart:34-37] [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:39-80] | Preservar; adicionar casos 899/900 aos testes. |
| Paleta claro/escuro aprovada | NÃ£o cumprido: o cÃ³digo usa `#12151C`, `#E3A452`, `#4FA9A6` e apenas tema escuro. [VERIFIED: lib/ui/app_theme.dart:4-17] [VERIFIED: lib/ui/app_theme.dart:64-133] | Substituir por tokens semÃ¢nticos da UI-SPEC e fornecer `light()`/`dark()` com paridade. |
| Spectral/Archivo/Space Mono locais | NÃ£o cumprido: cÃ³digo usa famÃ­lias anteriores e nÃ£o hÃ¡ `fonts:` no pubspec. [VERIFIED: lib/ui/app_theme.dart:39-61] [VERIFIED: pubspec.yaml:26-30] | Adicionar TTF/OTF locais 400/600 e licenÃ§as; declarar famÃ­lias exatas. |
| Escala de spacing | NÃ£o cumprido: atuais verbatim `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`; contrato exige `4, 8, 16, 24, 32, 48, 64`. [VERIFIED: lib/ui/app_theme.dart:19-26] [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:43-57] | Migrar todos os espaÃ§amentos para a escala aprovada; remover nÃºmeros ad hoc de layout. |
| Biblioteca editorial | Parcial: hÃ¡ cabeÃ§alho, card tracejado e lista, mas largura mÃ¡xima Ã© `920`, tÃ­tulo Ã© uma linha e progresso Ã© barra Material sem nÃºmero de catÃ¡logo/carimbo. [VERIFIED: lib/ui/widgets/library_view.dart:49-109] [VERIFIED: lib/ui/widgets/library_view.dart:312-401] | Usar mÃ¡ximo 960, tÃ­tulo atÃ© duas linhas, capa/marca, catÃ¡logo, regra 2 px e carimbo; completar microcopy e confirmaÃ§Ã£o. |
| Tema em Ajustes | Ausente: `SettingsView` sÃ³ apresenta seletor de engine. [VERIFIED: lib/ui/widgets/settings_view.dart:6-87] | Adicionar `Sistema`, `Claro`, `Escuro`, persistÃªncia local e teste de invariÃ¢ncia de leitura/foco. |
| Leitor editorial contÃ­nuo | Parcial: mantÃ©m `RichText` contÃ­nuo e imagens na ordem, mas mÃ¡ximo Ã© `780`, ativo usa fundo + sublinhado sÃ³lido e nÃ£o hÃ¡ auto-scroll. [VERIFIED: lib/ui/widgets/reader_page.dart:201-289] [VERIFIED: lib/ui/widgets/reader_document_view.dart:57-129] | MÃ¡ximo 760; ativo com ondulado grifo, pendente com colchetes/borda sinal; scroll somente fora do viewport e suspensÃ£o apÃ³s gesto manual. |
| ConfirmaÃ§Ã£o de retomada | NÃ£o cumprido: textos atuais sÃ£o `Retomar da frase N?`, `Cancelar`, `Continuar`. [VERIFIED: lib/ui/widgets/reader_page.dart:251-284] | Mostrar trecho escolhido e aÃ§Ãµes exatas `Manter posiÃ§Ã£o atual`/`Retomar daqui`; bottom sheet no telefone. |
| Player/telemetria | Parcial: player existe e reflowa a 430 px, mas MOS sempre habilita, scrubber usa trilha 4 px, mÃ©tricas ficam em uma Row e nÃ£o hÃ¡ painel tÃ©cnico recolhÃ­vel. [VERIFIED: lib/ui/widgets/audio_player_control_bar.dart:39-160] [VERIFIED: lib/ui/widgets/reader_page.dart:292-384] | Aplicar superfÃ­cie do tema, safe area, trilha 2 px, mÃ©tricas ausentes `â€”`, painel recolhÃ­vel e callbacks honestamente habilitados. |
| Teclado/foco | Parcial: reader liga Space/Escape/setas, mas nÃ£o hÃ¡ `Ctrl+O` nem ordem explÃ­cita navegaÃ§Ã£oâ†’conteÃºdoâ†’player. [VERIFIED: lib/ui/widgets/reader_page.dart:63-88] [VERIFIED: lib/main.dart:892-902] | Usar Actions/Shortcuts com guarda para foco editÃ¡vel e `FocusTraversalGroup`; foco 2 px em sinal. |
| ValidaÃ§Ã£o visual | Insuficiente: testes atuais cobrem 390 e 1200 apenas, somente tema escuro, sem goldens, 320 px, 200% ou guidelines de acessibilidade. [VERIFIED: test/ui/redesign_widgets_test.dart:14-218] | Implementar matriz completa da UI-SPEC e comparaÃ§Ã£o lado a lado. |

## Stack PadrÃ£o

### Core

| Biblioteca/SDK | VersÃ£o | Finalidade | Por que usar |
|---|---:|---|---|
| Flutter stable | 3.44.8 | Widgets, layout, tema, acessibilidade e desktop/mobile | A instalaÃ§Ã£o local informa verbatim `"frameworkVersion": "3.44.8"`, `"channel": "stable"`. [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-3] |
| Material 3 (`flutter/material.dart`) | SDK Flutter | NavigationBar, NavigationRail, ThemeData, controles e semÃ¢ntica base | O projeto jÃ¡ usa `useMaterial3: true`; manter widgets nativos tematizados. [VERIFIED: lib/ui/app_theme.dart:72-74] |
| `flutter_test` | SDK Flutter | Widget, semantics, guidelines e golden tests | JÃ¡ Ã© dependÃªncia SDK verbatim `flutter_test: sdk: flutter`. [VERIFIED: pubspec.yaml:21-24] |

### Suporte

| Biblioteca/asset | VersÃ£o | Finalidade | Quando usar |
|---|---:|---|---|
| `path_provider` | lock 2.1.6 | DiretÃ³rio application-support para preferÃªncia de tema jÃ¡ alinhado ao storage local existente | Usar somente para um repositÃ³rio mÃ­nimo de preferÃªncias, sem tocar no repositÃ³rio de EPUB. [VERIFIED: pubspec.lock:355-362] |
| Spectral, Archivo, Space Mono | binÃ¡rios locais a selecionar | Tipografia contratual | Empacotar arquivos TTF/OTF e declarar pesos 400/600; Flutter suporta `.ttf`/`.otf` em desktop e exige declaraÃ§Ã£o explÃ­cita de peso. [CITED: https://docs.flutter.dev/cookbook/design/fonts] |

### Alternativas Consideradas

| Em vez de | Poderia usar | Trade-off |
|---|---|---|
| Assets locais | `google_fonts` em runtime | Rejeitado: introduz dependÃªncia e risco de rede/cache incompatÃ­vel com a decisÃ£o offline; assets locais sÃ£o o contrato. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-39] |
| Widgets nativos | WebView/HTML | Proibido expressamente. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] |
| Responsividade por constraints | checagem `Platform.isAndroid/Windows` | Flutter recomenda decidir pelo espaÃ§o disponÃ­vel, nÃ£o pelo tipo de hardware/janela. [CITED: https://docs.flutter.dev/ui/adaptive-responsive/best-practices] |

**InstalaÃ§Ã£o:** nenhum pacote externo novo Ã© necessÃ¡rio. Adicionar somente arquivos de fonte e respectivas licenÃ§as ao repositÃ³rio. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:224-229]

## Auditoria de Legitimidade de Pacotes

NÃ£o aplicÃ¡vel: esta recomendaÃ§Ã£o nÃ£o instala pacote externo. Flutter, Material e `flutter_test` vÃªm do SDK; `path_provider` jÃ¡ estÃ¡ declarado/resolvido. [VERIFIED: pubspec.yaml:9-24] Se o planejador trocar esta decisÃ£o e introduzir um pacote, deverÃ¡ executar o gate de legitimidade antes do plano de instalaÃ§Ã£o. [ASSUMED]

Para os binÃ¡rios tipogrÃ¡ficos, adquirir somente da coleÃ§Ã£o oficial Google Fonts e versionar tambÃ©m o arquivo de licenÃ§a da famÃ­lia; o repositÃ³rio oficial declara que cada diretÃ³rio de famÃ­lia contÃ©m sua licenÃ§a. [CITED: https://github.com/google/fonts]

## PadrÃµes de Arquitetura

### Diagrama do Sistema

```text
Entrada Android/Windows
  toque | mouse | teclado | acessibilidade
                    |
                    v
      Actions/Shortcuts + FocusTraversal
                    |
                    v
 MaterialApp(theme, darkTheme, themeMode)
                    |
        +-----------+------------+
        |                        |
 largura < 900              largura >= 900
 NavigationBar              NavigationRail
        |                        |
        +-----------+------------+
                    |
     Biblioteca / Busca / Ajustes
                    |
             abrir livro
                    v
      Leitor contÃ­nuo (mÃ¡x. 760)
        | frase ativa/pending |
        v                    v
 auto-scroll condicionado   confirmaÃ§Ã£o
                    |
                    v
 player persistente + painel tÃ©cnico recolhÃ­vel
                    |
                    v
 callbacks existentes -> pipeline/audio/RTF/MOS/memÃ³ria offline
```

O fluxo mantÃ©m todas as decisÃµes no tier Flutter e usa callbacks para chegar aos serviÃ§os existentes, sem fazer a UI possuir engine, fila ou PCM. [VERIFIED: lib/main.dart:793-820] [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19]

### Estrutura Recomendada

```text
assets/fonts/                    # TTF/OTF + licenÃ§as das trÃªs famÃ­lias [ASSUMED]
lib/ui/
â”œâ”€â”€ app_theme.dart               # tokens semÃ¢nticos e ThemeData claro/escuro
â”œâ”€â”€ theme_preference.dart        # ThemeMode persistido localmente [ASSUMED]
â””â”€â”€ widgets/
    â”œâ”€â”€ responsive_navigation_shell.dart
    â”œâ”€â”€ library_view.dart
    â”œâ”€â”€ settings_view.dart
    â”œâ”€â”€ reader_page.dart
    â”œâ”€â”€ reader_document_view.dart
    â””â”€â”€ audio_player_control_bar.dart
test/ui/
â”œâ”€â”€ theme_contract_test.dart     # fontes/tokens/tema/persistÃªncia [ASSUMED]
â”œâ”€â”€ redesign_widgets_test.dart
â”œâ”€â”€ accessibility_test.dart      # guidelines/semantics/foco [ASSUMED]
â””â”€â”€ goldens/                     # biblioteca/leitor, temas e viewports [ASSUMED]
```

Os nomes novos acima sÃ£o uma recomendaÃ§Ã£o de organizaÃ§Ã£o e ainda nÃ£o existem; o planejador pode ajustÃ¡-los mantendo responsabilidades separadas. [ASSUMED]

### PadrÃ£o 1: Tokens semÃ¢nticos como fonte Ãºnica

**O que:** definir cores, spacing e os quatro papÃ©is tipogrÃ¡ficos em uma Ãºnica camada; widgets consultam `Theme.of(context)`/ThemeExtension e nÃ£o importam cores claras/escuras fixas. O Material obtÃ©m aparÃªncia principalmente de `colorScheme` e `textTheme`. [CITED: https://api.flutter.dev/flutter/material/ThemeData-class.html]

**Quando usar:** em todos os widgets da fase. O cÃ³digo atual fixa `AppColors` globais, impedindo paridade de temas. [VERIFIED: lib/ui/app_theme.dart:4-17]

### PadrÃ£o 2: Responsividade por constraints e composiÃ§Ã£o compartilhada

**O que:** `LayoutBuilder` decide apenas a composiÃ§Ã£o; os mesmos subwidgets/callbacks alimentam variantes compacta e larga. Flutter diferencia `LayoutBuilder` por fornecer constraints do ponto especÃ­fico da Ã¡rvore. [CITED: https://docs.flutter.dev/ui/adaptive-responsive/general]

**Quando usar:** shell, biblioteca, leitor, player e painÃ©is. Preservar os valores verbatim do contrato: `"<600px"`, `"600â€“899px"`, `"â‰¥900px"`, mÃ¡ximo `"960px"` para biblioteca e `"760px"` para leitura. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-177]

### PadrÃ£o 3: AÃ§Ãµes independentes do dispositivo de entrada

**O que:** um Intent/Action representa importar, play/pause, fechar seleÃ§Ã£o e mover frase; toque, menu, botÃ£o e atalho invocam a mesma aÃ§Ã£o. O sistema Flutter separa atalhos, intents e actions para que o binding fique distante da implementaÃ§Ã£o. [CITED: https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts]

**Quando usar:** `Space`, `Escape`, setas e `Ctrl+O`; impedir captura quando `FocusManager.instance.primaryFocus?.context` estiver em um `EditableText`. Eventos de foco sÃ£o processados antes da entrada de texto e podem impedir a digitaÃ§Ã£o se tratados no ancestral. [CITED: https://docs.flutter.dev/ui/interactivity/focus]

### PadrÃ£o 4: Auto-scroll orientado por visibilidade, nÃ£o por Ã­ndice

**O que:** manter contexto/chave estÃ¡vel por frase, verificar se o render object saiu do viewport e chamar `Scrollable.ensureVisible` apenas entÃ£o; gesto manual suspende o movimento atÃ© a prÃ³xima mudanÃ§a de frase/comando. `Scrollable.ensureVisible` torna o alvo visÃ­vel e aceita `Duration.zero`. [CITED: https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html]

**Quando usar:** somente para mudanÃ§a aceita de frase ativa. Se `MediaQuery.disableAnimationsOf(context)` for verdadeiro, usar duraÃ§Ã£o zero; a API representa pedido da plataforma para reduzir/desabilitar animaÃ§Ãµes. [CITED: https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html]

### PadrÃ£o 5: Estado visual explÃ­cito e testÃ¡vel

**O que:** modelar importaÃ§Ã£o, engine, leitura, playback, mÃ©tricas e tema como estados controlados; cada estado gera copy e aÃ§Ã£o definidas na UI-SPEC. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:183-205]

**Quando usar:** evitar strings ad hoc e flags acopladas. Hoje o card de importaÃ§Ã£o usa `isProcessing`, que tambÃ©m representa sÃ­ntese. [VERIFIED: lib/ui/widgets/library_view.dart:6-32] [VERIFIED: lib/ui/widgets/library_view.dart:158-214]

### Anti-padrÃµes a Evitar

- **Cores/fontes fixas no widget:** impedem temas e tornam o contrato impossÃ­vel de auditar; use tokens/ThemeData. [VERIFIED: lib/ui/widgets/library_view.dart:112-155]
- **Recriar recognizers em `build`:** o cÃ³digo atual os descarta e recria em cada rebuild, podendo perder um tap entre pointer down/up. [VERIFIED: lib/ui/widgets/reader_document_view.dart:31-64]
- **Scroll automÃ¡tico contÃ­nuo:** conflita com a leitura manual; mover apenas quando a frase sai do viewport. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:150-155]
- **MÃ©trica falsa zero:** ausÃªncia deve ser `â€”`; nunca derivar dado visual sem snapshot vÃ¡lido. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:157-162]
- **Golden Ãºnico por mÃ¡quina sem fonte empacotada:** fallbacks variam entre Windows/Android e tornam renderizaÃ§Ã£o instÃ¡vel; empacotar fontes antes de capturar g…969 tokens truncated…ovimento reduzido nÃ£o anima scroll. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
await Scrollable.ensureVisible(
  sentenceContext,
  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
);
```

A API oficial documenta `disableAnimationsOf` e `Scrollable.ensureVisible`; o gatilho adicional â€œsomente fora do viewportâ€ deve ser testado pelo widget. [CITED: https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html] [CITED: https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html]

## Armadilhas Comuns

### 1. Tratar o plano 14 executado como fidelidade concluÃ­da

**Falha:** o shell responsivo existe, mas o design system ainda Ã© o anterior. [VERIFIED: lib/ui/app_theme.dart:3-17]  
**Como evitar:** o novo plano deve ter critÃ©rios por token, tipografia, tema, composiÃ§Ã£o e golden, nÃ£o â€œlayout responsivoâ€ genÃ©rico. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:28-74]

### 2. Capturar goldens antes de empacotar fontes

**Falha:** fallback local produz mÃ©tricas diferentes entre plataformas. [CITED: https://docs.flutter.dev/cookbook/design/fonts]  
**Como evitar:** fontes + pubspec + teste de resoluÃ§Ã£o das famÃ­lias devem ser Wave 0 da UI.

### 3. Quebrar texto a 200%

**Falha:** `Row` com status/contadores ou player fixo estoura; o status atual estÃ¡ em uma Ãºnica `Row`. [VERIFIED: lib/ui/widgets/reader_page.dart:342-366]  
**Como evitar:** `Wrap`, `Flexible`, scroll vertical em altura baixa e testes com `TextScaler.linear(2.0)`. O `textScaler` reflete preferÃªncia do sistema. [CITED: https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html]

### 4. Atalho impedir digitaÃ§Ã£o

**Falha:** Shortcuts/Focus processam a tecla antes do campo. [CITED: https://docs.flutter.dev/ui/interactivity/focus]  
**Como evitar:** nÃ£o tratar Space/setas/Ctrl+O quando o foco primÃ¡rio estÃ¡ em `EditableText`; teste especÃ­fico no campo de busca.

### 5. Auto-scroll disputar com gesto manual

**Falha:** acompanhar cada rebuild remove controle do usuÃ¡rio. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:150-155]  
**Como evitar:** detectar `UserScrollNotification`, suspender atÃ© prÃ³xima mudanÃ§a de frase/comando e sÃ³ garantir visibilidade se fora do viewport.

### 6. Usar cor como Ãºnico sinal

**Falha:** ativo e pendente ficam indistinguÃ­veis para baixa visÃ£o/leitor de tela. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:78-105]  
**Como evitar:** ativo = peso + ondulado + semantics â€œfrase atualâ€; pendente = colchetes/borda + semantics â€œseleÃ§Ã£o pendenteâ€.

### 7. Alterar pipeline durante o redesign

**Falha:** acopla risco funcional ao visual e viola decisÃ£o bloqueada. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19]  
**Como evitar:** UI recebe snapshots/callbacks; planos 14-02â€“14-06 continuam donos de persistÃªncia, streaming e telemetria.

## Impacto nos Planos Existentes

| Plano | Direção prescritiva |
|---|---|
| 14-PLAN / 14-SUMMARY | Preservar como base estrutural executada; não reabrir nem reutilizar o output. |
| 14-02 | Preservar identidade/storage executado em `5fc8bb0`; não reagendar persistência. |
| 14-03 / 14-03-SUMMARY | Preservar ownership/cancelamento/streaming executado em `cf5acc7`; não reagendar streaming. |
| 14-04 | Fundação visual pendente: fontes oficiais locais, tokens, temas e preferência persistida. |
| 14-05 | Biblioteca/importação editorial, progresso e estados coerentes sobre 14-02/14-03/14-04. |
| 14-06 | Telemetria metadata-only real, fila e memória, consumindo o streaming já executado. |
| 14-07 | Leitor contínuo, auto-scroll, player e painel técnico sobre tema/telemetria. |
| 14-08 | Acessibilidade, atalhos, estados e matriz responsiva. |
| 14-09 | Goldens no host/engine Windows canônico após fontes e contratos estabilizados. |
| 14-10 | UAT nativo Android/Windows e aprovação visual final. |

Ordem final: **histórico executado 14-01/02/03 → fundação UI 14-04 → biblioteca 14-05 → telemetria 14-06 → leitor/player 14-07 → acessibilidade 14-08 → goldens 14-09 → UAT 14-10**.

## Estado da Arte

| Abordagem antiga no projeto | Abordagem exigida agora | Impacto |
|---|---|---|
| Tema escuro Ãºnico e cores globais | `theme`, `darkTheme`, `themeMode` e tokens semÃ¢nticos | Paridade claro/escuro/sistema. [CITED: https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html] |
| Fontes declaradas apenas por nome/fallback | Fontes TTF/OTF empacotadas no pubspec com peso explÃ­cito | Fidelidade e goldens determinÃ­sticos. [CITED: https://docs.flutter.dev/cookbook/design/fonts] |
| CallbackShortcuts direto | Actions/Shortcuts + traversal/foco editÃ¡vel protegido | Atalhos desktop sem quebrar busca. [CITED: https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts] |
| Teste de presenÃ§a em dois tamanhos | Matriz widget + golden + semantics + guidelines | Verifica fidelidade, overflow e acessibilidade. [CITED: https://docs.flutter.dev/ui/accessibility/accessibility-testing] |

**Deprecado no repositÃ³rio:** `withOpacity` em `sentence_highlight_view.dart` foi reportado como deprecated por `dart analyze`; usar `.withValues()` se esse widget continuar em uso. [VERIFIED: dart analyze 2026-08-03]

## Log de SuposiÃ§Ãµes

| # | AlegaÃ§Ã£o assumida | SeÃ§Ã£o | Risco se errada |
|---|---|---|---|
| A2 | Novos arquivos `theme_preference.dart`, `theme_contract_test.dart`, `accessibility_test.dart` e diretÃ³rio `goldens/` sÃ£o a melhor decomposiÃ§Ã£o. | Estrutura | O planner pode preferir nomes/organizaÃ§Ã£o existentes; responsabilidade Ã© mais importante que nome. |
| A3 | A ordem de waves proposta Ã© a melhor forma de atualizar os planos. | Impacto nos planos | DependÃªncias reais/ownership podem exigir divisÃ£o diferente, mas fundaÃ§Ã£o deve preceder goldens. |
| A4 | Qualquer pacote futuro deve passar gate de legitimidade. | Auditoria | SÃ³ se aplica se o planejador decidir adicionar dependÃªncia externa. |
| A5 | Os comandos rÃ¡pidos e nomes dos novos arquivos de teste serÃ£o exatamente os propostos. | ValidaÃ§Ã£o | O planner pode consolidar arquivos ou mudar `--plain-name`; preservar a cobertura, nÃ£o o nome. |
| A7 | Harnesses, factories de fixtures e a taxa de amostragem proposta serÃ£o adotados. | ValidaÃ§Ã£o/Wave 0 | Outra infraestrutura pode ser igualmente vÃ¡lida, desde que execute a mesma matriz. |

## Perguntas em Aberto — RESOLVED

As três questões foram resolvidas para tornar a execução determinística e preservar o histórico da fase:

1. **RESOLVED — binários oficiais das fontes**
   - Versionar arquivos estáticos da coleção oficial Google Fonts: `Spectral-Regular.ttf` (400), `Spectral-SemiBold.ttf` (600), `Archivo-Regular.ttf` (400), `Archivo-SemiBold.ttf` (600), `SpaceMono-Regular.ttf` (400) e `SpaceMono-SemiBold.ttf` (600).
   - Versionar junto aos binários o `OFL.txt` oficial de cada família e validar glyphs pt-BR antes de qualquer captura golden.
   - Não usar variable fonts, download em runtime ou fallback como entrega final.

2. **RESOLVED — numeração sem colisão histórica**
   - Preservar `14-PLAN.md`/`14-SUMMARY.md` como Plano 14-01 executado, `14-02-PLAN.md` como storage executado pelo commit `5fc8bb0` e `14-03-PLAN.md`/`14-03-SUMMARY.md` como streaming executado pelo commit `cf5acc7`.
   - O trabalho visual realmente pendente começa em `14-04-PLAN.md`. Nenhum plano pendente pode produzir um SUMMARY já existente para outro subsistema.

3. **RESOLVED — autoridade canônica dos goldens**
   - Windows nativo, com Flutter 3.44.8 stable e o renderer declarado pelo harness de `flutter test`, é a única autoridade para atualizar baselines.
   - Android e outros hosts não regravam baselines: validam invariantes cross-platform por testes de widget, layout e semantics.
   - Toda atualização golden exige fontes empacotadas, harness determinístico, comando explícito de update e revisão do diff.

## Disponibilidade do Ambiente

| DependÃªncia | Requerida por | DisponÃ­vel | VersÃ£o | Fallback |
|---|---|---:|---:|---|
| Flutter SDK | build/anÃ¡lise/testes | âœ“ | 3.44.8 stable | â€” [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-13] |
| Dart SDK | anÃ¡lise | âœ“ | 3.12.2 | â€” [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:11-13] |
| Android shell | UAT Android | âœ“ no repositÃ³rio | Flutter Gradle plugin e namespace existentes | dispositivo fÃ­sico continua obrigatÃ³rio. [VERIFIED: android/app/build.gradle.kts:1-25] |
| Windows shell | UAT Windows | âœ“ no repositÃ³rio | CMake mÃ­nimo 3.14; binÃ¡rio `tcc_tts_neural` | mÃ¡quina Windows nativa continua obrigatÃ³ria. [VERIFIED: windows/CMakeLists.txt:1-11] |
| Fontes locais | fidelidade/goldens | âœ— | â€” | bloqueador da fundaÃ§Ã£o visual; fallbacks nÃ£o satisfazem entrega final. [VERIFIED: workspace font asset audit] |

`dart analyze lib/ui lib/main.dart test/ui/redesign_widgets_test.dart test/ui/audio_player_widget_test.dart` concluiu com somente 2 infos de depreciaÃ§Ã£o em `sentence_highlight_view.dart`. [VERIFIED: command run 2026-08-03] O comando Flutter ficou bloqueado enquanto havia processos Flutter/Dart concorrentes; os testes nÃ£o foram usados como evidÃªncia de aprovaÃ§Ã£o nesta pesquisa. [VERIFIED: environment process audit 2026-08-03]

## Arquitetura de ValidaÃ§Ã£o

### Framework de Teste

| Propriedade | Valor |
|---|---|
| Framework | `flutter_test` do Flutter SDK 3.44.8 [VERIFIED: pubspec.yaml:21-24] |
| ConfiguraÃ§Ã£o | `analysis_options.yaml`; nÃ£o hÃ¡ config golden dedicada observada. [VERIFIED: workspace root audit] |
| Comando rÃ¡pido | `flutter test --no-pub test/ui/theme_contract_test.dart test/ui/redesign_widgets_test.dart` [ASSUMED] |
| SuÃ­te completa | `flutter test --no-pub` [ASSUMED] |

### Contrato â†’ Mapa de Testes

| Contrato | Comportamento | Tipo | Comando automatizado | Existe? |
|---|---|---|---|---|
| Tema/fontes | famÃ­lias exatas, quatro tamanhos, dois pesos, temas claro/escuro/sistema persistido | widget/unit | `flutter test --no-pub test/ui/theme_contract_test.dart` | âŒ Wave 0 [ASSUMED] |
| NavegaÃ§Ã£o | barra <900; rail >=900; 899/900; foco inicial | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name navigation` | âš ï¸ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:18-61] |
| Biblioteca | 0/1/muitos, busca vazia, tÃ­tulos longos, todos estados de importaÃ§Ã£o, delete | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name biblioteca` | âš ï¸ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:63-140] |
| Leitor | texto/imagem, vazio/parcial/erro, ativo/pending, auto-scroll/manual, retomada | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name leitor` | âš ï¸ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:142-217] |
| Player/mÃ©tricas | todos estados, scrubber teclado/mouse/toque, MOS/report, painel recolhÃ­vel, `â€”` ausente | widget/integration | `flutter test --no-pub test/ui/audio_player_widget_test.dart test/ui/telemetry_flow_test.dart` | âš ï¸ parcial; telemetry_flow ainda planejado [VERIFIED: test/ui/audio_player_widget_test.dart:10-125] |
| Atalhos/foco | Space/Escape/setas/Ctrl+O; TextField nÃ£o captura | widget | `flutter test --no-pub test/ui/accessibility_test.dart --plain-name atalhos` | âŒ Wave 0 [ASSUMED] |
| Acessibilidade | targets, labels, contraste, text scale 200%, reduced motion | guideline/widget | `flutter test --no-pub test/ui/accessibility_test.dart` | âŒ Wave 0 [ASSUMED] |
| Fidelidade | biblioteca/leitor 390Ã—844, 800Ã—1280, 1440Ã—900 em claro/escuro | golden | `flutter test --no-pub test/ui/golden_test.dart` | âŒ Wave 0 [ASSUMED] |
| Robustez estreita | 320 px e janela baixa sem overflow | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name overflow` | âŒ Wave 0 [ASSUMED] |

### Matriz mÃ­nima obrigatÃ³ria

| Viewport | Claro | Escuro | Texto 200% | Estado crÃ­tico |
|---|---:|---:|---:|---|
| 320Ã—568 | widget | widget | âœ“ | player wrap + tÃ­tulos longos [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-179] |
| 390Ã—844 | golden | golden | âœ“ | biblioteca e leitor [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 800Ã—1280 | golden | golden | âœ“ | tablet/barra inferior [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 1440Ã—900 | golden | golden | âœ“ | rail + leitor/player lateral [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 899Ã—900 / 900Ã—900 | widget | widget | â€” | limite exato do breakpoint [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-179] |

### Taxa de Amostragem

- **Por commit de tarefa:** teste do arquivo tocado + `dart analyze` dos arquivos modificados. [ASSUMED]
- **Por merge de wave:** suÃ­te UI inteira em temas claro/escuro. [ASSUMED]
- **Gate da fase:** `flutter test --no-pub`, anÃ¡lise sem erros, goldens aprovados, guidelines de acessibilidade e UAT Android/Windows. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

### Gaps Wave 0

- [ ] adquirir e versionar fontes/licenÃ§as; declarar no pubspec; validar pesos 400/600. [VERIFIED: workspace font asset audit]
- [ ] criar harness de tema e preferÃªncia persistida. [ASSUMED]
- [ ] criar factories de fixtures para biblioteca/leitor/player sem duplicar dezenas de callbacks. [ASSUMED]
- [ ] criar helper de viewport + `TextScaler.linear(2.0)` + reset seguro. [CITED: https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html]
- [ ] criar baselines golden canÃ´nicos somente apÃ³s fontes/tokens estabilizarem. [CITED: https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html]
- [ ] adicionar `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline` e `textContrastGuideline`. [CITED: https://docs.flutter.dev/ui/accessibility/accessibility-testing]

## DomÃ­nio de SeguranÃ§a

### Categorias ASVS AplicÃ¡veis

| Categoria ASVS | Aplica | Controle padrÃ£o |
|---|---|---|
| V2 AutenticaÃ§Ã£o | nÃ£o | App offline sem autenticaÃ§Ã£o no escopo. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |
| V3 SessÃ£o | nÃ£o | NÃ£o hÃ¡ sessÃ£o remota no escopo. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |
| V4 Controle de acesso | nÃ£o | Dados ficam no storage privado da aplicaÃ§Ã£o; redesign nÃ£o muda boundary. [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] |
| V5 ValidaÃ§Ã£o de entrada | sim | Picker/importador continuam validando EPUB; UI sÃ³ mapeia erro para copy segura. [VERIFIED: .planning/phases/14-ui-redesign/14-04-PLAN.md] |
| V6 Criptografia | sim, somente integridade de identidade | SHA-256 via pacote existente no Plano 14-02; nunca implementar hash manual. [VERIFIED: pubspec.yaml:18-19] [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] |

### PadrÃµes de AmeaÃ§a do Stack

| PadrÃ£o | STRIDE | MitigaÃ§Ã£o |
|---|---|---|
| Atalho dispara importaÃ§Ã£o enquanto usuÃ¡rio digita | Tampering/DoS | Ignorar shortcut quando foco estiver em `EditableText`; single-flight do Plano 14-04. [CITED: https://docs.flutter.dev/ui/interactivity/focus] |
| Mensagem expÃµe path/exceÃ§Ã£o | Information Disclosure | Copy principal segura; detalhes somente Ã¡rea tÃ©cnica expansÃ­vel. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:123-133] |
| Web/font asset remoto quebra offline | Information Disclosure/DoS | Nenhum WebView/recurso remoto; assets empacotados. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] |
| Estado visual stale dispara Ã¡udio antigo | Tampering | Ownership/generation do Plano 14-03; UI nÃ£o cria stream prÃ³prio. [VERIFIED: .planning/phases/14-ui-redesign/14-03-PLAN.md] |
| Telemetria prolonga vida do PCM | DoS | Snapshot somente de escalares; planos 14-05/06 mantÃªm fila proprietÃ¡ria do Ã¡udio. [VERIFIED: .planning/phases/14-ui-redesign/14-05-PLAN.md] |

## Fontes

### PrimÃ¡rias (ALTA confianÃ§a local)

- `.planning/phases/14-ui-redesign/14-CONTEXT.md` â€” decisÃµes bloqueadas.
- `.planning/phases/14-ui-redesign/14-UI-SPEC.md` â€” contrato aprovado completo.
- `lib/ui/app_theme.dart`, `lib/ui/widgets/*`, `lib/main.dart`, `test/ui/*`, `pubspec.yaml`, `pubspec.lock` â€” estado real do cÃ³digo aberto nesta sessÃ£o.
- `C:/Users/55759/flutter/bin/cache/flutter.version.json` â€” versÃ£o local do SDK.

### SecundÃ¡rias (MÃ‰DIA confianÃ§a; documentaÃ§Ã£o oficial consultada via WebSearch)

- https://docs.flutter.dev/ui/adaptive-responsive/general â€” LayoutBuilder e composiÃ§Ã£o adaptativa.
- https://docs.flutter.dev/ui/adaptive-responsive/best-practices â€” espaÃ§o disponÃ­vel, nÃ£o tipo de hardware.
- https://docs.flutter.dev/cookbook/design/fonts â€” fontes locais, formatos e pesos.
- https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html â€” ThemeMode.
- https://docs.flutter.dev/ui/interactivity/focus â€” foco, traversal e conflito com entrada de texto.
- https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts â€” Actions/Shortcuts.
- https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html â€” visibilidade da frase.
- https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html â€” movimento reduzido.
- https://docs.flutter.dev/ui/accessibility/accessibility-testing â€” guidelines automatizadas.
- https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html â€” golden testing.
- https://github.com/google/fonts â€” fonte/licenÃ§as das famÃ­lias.

### TerciÃ¡rias (BAIXA confianÃ§a)

- Nenhuma fonte web nÃ£o oficial foi usada; decisÃµes ainda nÃ£o verificadas estÃ£o marcadas `[ASSUMED]`.

## Metadados

**Quebra de confianÃ§a:**
- Stack padrÃ£o: ALTA â€” SDK e dependÃªncias verificados localmente; documentaÃ§Ã£o oficial atual reflete Flutter 3.44.7 e o SDK local Ã© 3.44.8. [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-13] [CITED: https://docs.flutter.dev/ui/adaptive-responsive/general]
- Arquitetura: ALTA â€” deriva do contrato aprovado e dos widgets reais abertos nesta sessÃ£o. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md]
- Armadilhas: ALTA para gaps locais; MÃ‰DIA para recomendaÃ§Ãµes de APIs externas consultadas via WebSearch oficial.
- ValidaÃ§Ã£o: ALTA para a matriz obrigatÃ³ria; MÃ‰DIA para filenames/organizaÃ§Ã£o dos novos testes.

**Data da pesquisa:** 2026-08-03  
**VÃ¡lida atÃ©:** 2026-09-02 para o contrato local; revalidar documentaÃ§Ã£o/SDK se Flutter for atualizado.
