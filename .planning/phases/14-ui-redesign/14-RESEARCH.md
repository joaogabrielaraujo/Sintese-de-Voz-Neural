# Fase 14: Redesign da UI e Leitor Responsivo Android/Windows — Pesquisa

**Pesquisado em:** 2026-08-03  
**Domínio:** Flutter Material 3 nativo, UI editorial adaptativa, acessibilidade e validação visual  
**Confiança:** ALTA para o diagnóstico do repositório e o contrato; MÉDIA para padrões externos consultados por documentação oficial via WebSearch

<user_constraints>
## Restrições do Usuário (de CONTEXT.md)

### Decisões Bloqueadas

- O mockup é referência visual; não será embutido como HTML.
- Android prioriza leitura vertical, controles acessíveis ao toque e navegação inferior.
- Windows usa layout largo com navegação lateral, mouse, teclado e conteúdo centralizado.
- O redesign não altera o pipeline de síntese, importação, fila, memória, RTF ou MOS.
- Fontes externas não serão carregadas pela rede em runtime; usar fontes empacotadas ou fallbacks locais.

### the agent's Discretion

Nenhuma seção `## o agente's Discretion` existe em `14-CONTEXT.md`.

### Deferred Ideas (OUT OF SCOPE)

Nenhuma seção `## Deferred Ideas` existe em `14-CONTEXT.md`. A paginação por página original está explicitamente adiada em `STATE.md` e nos planos existentes; preservar leitura contínua. [VERIFIED: .planning/STATE.md:29-33]
</user_constraints>

## Resumo

O plano executado `14-PLAN.md` entregou separação inicial de widgets e o breakpoint estrutural correto, mas não implementou o contrato visual aprovado. O código atual ainda declara somente tema escuro, usa as famílias `"Literata"`, `"Manrope"` e `"JetBrains Mono"`, e contém a paleta antiga `ink/amber/teal`; o contrato exige exatamente `"Spectral"`, `"Archivo"`, `"Space Mono"`, temas claro/escuro e os tokens papel/sinal/grifo/musgo. Citação verificável do código atual: `fontFamily: 'Literata'`, `fontFamily: 'JetBrains Mono'`, `fontFamily: 'Manrope'` e apenas `static ThemeData dark()`. [VERIFIED: lib/ui/app_theme.dart:39-65] O `pubspec.yaml` não contém uma seção `fonts:`; após `uses-material-design: true` ele declara diretamente `assets:`. [VERIFIED: pubspec.yaml:26-30]

O shell adaptativo já preserva a decisão essencial: `AppDestination { library, search, settings }`, `AppBreakpoints.wide = 900.0`, `NavigationRail` para `maxWidth >= wide` e `NavigationBar` abaixo disso. Esses valores verbatim são a base correta e devem ser mantidos. [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:5-35] [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:37-80] [VERIFIED: lib/ui/app_theme.dart:34-37] Porém biblioteca, leitor, player, ajustes, estados e testes ainda divergem amplamente da UI-SPEC: não há preferência de tema, fontes locais, auto-scroll da frase ativa, painel técnico recolhível, safe areas explícitas, `Ctrl+O`, ordem de foco, goldens ou cobertura a 200% de texto. [VERIFIED: lib/main.dart:32-43] [VERIFIED: lib/ui/widgets/settings_view.dart:6-87] [VERIFIED: lib/ui/widgets/reader_document_view.dart:31-129] [VERIFIED: test/ui/redesign_widgets_test.dart:14-218]

Os planos 14-02 a 14-06 tratam principalmente durabilidade, concorrência e telemetria; são necessários para preservar verdade funcional, mas não substituem a implementação do UI-SPEC. O planejador deve reabrir a entrega visual como um plano corretivo de fundação antes das alterações de biblioteca/leitor e ampliar 14-04, 14-06 e 14-07 para os contratos visuais correspondentes. [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] [VERIFIED: .planning/phases/14-ui-redesign/14-07-PLAN.md]

**Recomendação principal:** criar primeiro a fundação de design nativa (assets tipográficos, tokens semânticos, temas e preferência persistida), depois aplicar esses contratos à biblioteca/ajustes e ao leitor/player, e só então fechar com a matriz widget/golden/acessibilidade e UAT Android/Windows. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-39] [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

## Mapa de Responsabilidade Arquitetural

| Capacidade | Tier primário | Tier secundário | Razão |
|---|---|---|---|
| Tokens, tipografia, tema e movimento reduzido | Browser / Client (Flutter UI) | Storage local | `ThemeData`, `MediaQuery` e preferência de tema pertencem à apresentação; somente a escolha persistida cruza para storage. [CITED: https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html] |
| Shell Biblioteca/Busca/Ajustes | Browser / Client (Flutter UI) | — | O código já concentra a troca `NavigationBar`/`NavigationRail` no shell de widgets. [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:37-80] |
| Biblioteca editorial e estados de importação | Browser / Client (Flutter UI) | API/Backend local | Widgets apresentam estado e disparam callbacks; importador e repositório continuam fora da camada visual. [VERIFIED: lib/ui/widgets/library_view.dart:6-32] [VERIFIED: lib/main.dart:840-863] |
| Leitor sincronizado e auto-scroll | Browser / Client (Flutter UI) | API/Backend local | O widget renderiza frases/blocos e recebe índices/callbacks; pipeline continua proprietário da síntese. [VERIFIED: lib/ui/widgets/reader_document_view.dart:11-25] [VERIFIED: lib/ui/widgets/reader_page.dart:11-61] |
| Player persistente e telemetria recolhível | Browser / Client (Flutter UI) | API/Backend local | Controles e métricas são apresentação de `IAudioPlayerService`/estado do pipeline, sem reter PCM na UI. [VERIFIED: lib/ui/widgets/audio_player_control_bar.dart:6-30] [VERIFIED: .planning/phases/14-ui-redesign/14-06-PLAN.md] |
| EPUB, fila, memória, RTF e MOS | API/Backend local | Storage local | CONTEXT proíbe mudar essas fronteiras; os planos 14-02–14-06 fecham consistência e telemetria sem alterar o princípio offline. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |

## Auditoria do Estado Atual contra a UI-SPEC

| Contrato | Estado atual | Trabalho obrigatório |
|---|---|---|
| Flutter nativo, sem HTML | Cumprido: não há `WebView` no código pesquisado; UI é composta por widgets Flutter. [VERIFIED: codebase audit via `rg` e .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] | Manter a proibição e nunca adicionar o HTML aos assets de runtime. |
| Breakpoint de navegação 900 px | Cumprido: valor verbatim `wide = 900.0`; rail acima e barra abaixo. [VERIFIED: lib/ui/app_theme.dart:34-37] [VERIFIED: lib/ui/widgets/responsive_navigation_shell.dart:39-80] | Preservar; adicionar casos 899/900 aos testes. |
| Paleta claro/escuro aprovada | Não cumprido: o código usa `#12151C`, `#E3A452`, `#4FA9A6` e apenas tema escuro. [VERIFIED: lib/ui/app_theme.dart:4-17] [VERIFIED: lib/ui/app_theme.dart:64-133] | Substituir por tokens semânticos da UI-SPEC e fornecer `light()`/`dark()` com paridade. |
| Spectral/Archivo/Space Mono locais | Não cumprido: código usa famílias anteriores e não há `fonts:` no pubspec. [VERIFIED: lib/ui/app_theme.dart:39-61] [VERIFIED: pubspec.yaml:26-30] | Adicionar TTF/OTF locais 400/600 e licenças; declarar famílias exatas. |
| Escala de spacing | Não cumprido: atuais verbatim `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`; contrato exige `4, 8, 16, 24, 32, 48, 64`. [VERIFIED: lib/ui/app_theme.dart:19-26] [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:43-57] | Migrar todos os espaçamentos para a escala aprovada; remover números ad hoc de layout. |
| Biblioteca editorial | Parcial: há cabeçalho, card tracejado e lista, mas largura máxima é `920`, título é uma linha e progresso é barra Material sem número de catálogo/carimbo. [VERIFIED: lib/ui/widgets/library_view.dart:49-109] [VERIFIED: lib/ui/widgets/library_view.dart:312-401] | Usar máximo 960, título até duas linhas, capa/marca, catálogo, regra 2 px e carimbo; completar microcopy e confirmação. |
| Tema em Ajustes | Ausente: `SettingsView` só apresenta seletor de engine. [VERIFIED: lib/ui/widgets/settings_view.dart:6-87] | Adicionar `Sistema`, `Claro`, `Escuro`, persistência local e teste de invariância de leitura/foco. |
| Leitor editorial contínuo | Parcial: mantém `RichText` contínuo e imagens na ordem, mas máximo é `780`, ativo usa fundo + sublinhado sólido e não há auto-scroll. [VERIFIED: lib/ui/widgets/reader_page.dart:201-289] [VERIFIED: lib/ui/widgets/reader_document_view.dart:57-129] | Máximo 760; ativo com ondulado grifo, pendente com colchetes/borda sinal; scroll somente fora do viewport e suspensão após gesto manual. |
| Confirmação de retomada | Não cumprido: textos atuais são `Retomar da frase N?`, `Cancelar`, `Continuar`. [VERIFIED: lib/ui/widgets/reader_page.dart:251-284] | Mostrar trecho escolhido e ações exatas `Manter posição atual`/`Retomar daqui`; bottom sheet no telefone. |
| Player/telemetria | Parcial: player existe e reflowa a 430 px, mas MOS sempre habilita, scrubber usa trilha 4 px, métricas ficam em uma Row e não há painel técnico recolhível. [VERIFIED: lib/ui/widgets/audio_player_control_bar.dart:39-160] [VERIFIED: lib/ui/widgets/reader_page.dart:292-384] | Aplicar superfície do tema, safe area, trilha 2 px, métricas ausentes `—`, painel recolhível e callbacks honestamente habilitados. |
| Teclado/foco | Parcial: reader liga Space/Escape/setas, mas não há `Ctrl+O` nem ordem explícita navegação→conteúdo→player. [VERIFIED: lib/ui/widgets/reader_page.dart:63-88] [VERIFIED: lib/main.dart:892-902] | Usar Actions/Shortcuts com guarda para foco editável e `FocusTraversalGroup`; foco 2 px em sinal. |
| Validação visual | Insuficiente: testes atuais cobrem 390 e 1200 apenas, somente tema escuro, sem goldens, 320 px, 200% ou guidelines de acessibilidade. [VERIFIED: test/ui/redesign_widgets_test.dart:14-218] | Implementar matriz completa da UI-SPEC e comparação lado a lado. |

## Stack Padrão

### Core

| Biblioteca/SDK | Versão | Finalidade | Por que usar |
|---|---:|---|---|
| Flutter stable | 3.44.8 | Widgets, layout, tema, acessibilidade e desktop/mobile | A instalação local informa verbatim `"frameworkVersion": "3.44.8"`, `"channel": "stable"`. [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-3] |
| Material 3 (`flutter/material.dart`) | SDK Flutter | NavigationBar, NavigationRail, ThemeData, controles e semântica base | O projeto já usa `useMaterial3: true`; manter widgets nativos tematizados. [VERIFIED: lib/ui/app_theme.dart:72-74] |
| `flutter_test` | SDK Flutter | Widget, semantics, guidelines e golden tests | Já é dependência SDK verbatim `flutter_test: sdk: flutter`. [VERIFIED: pubspec.yaml:21-24] |

### Suporte

| Biblioteca/asset | Versão | Finalidade | Quando usar |
|---|---:|---|---|
| `path_provider` | lock 2.1.6 | Diretório application-support para preferência de tema já alinhado ao storage local existente | Usar somente para um repositório mínimo de preferências, sem tocar no repositório de EPUB. [VERIFIED: pubspec.lock:355-362] |
| Spectral, Archivo, Space Mono | binários locais a selecionar | Tipografia contratual | Empacotar arquivos TTF/OTF e declarar pesos 400/600; Flutter suporta `.ttf`/`.otf` em desktop e exige declaração explícita de peso. [CITED: https://docs.flutter.dev/cookbook/design/fonts] |

### Alternativas Consideradas

| Em vez de | Poderia usar | Trade-off |
|---|---|---|
| Assets locais | `google_fonts` em runtime | Rejeitado: introduz dependência e risco de rede/cache incompatível com a decisão offline; assets locais são o contrato. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-39] |
| Widgets nativos | WebView/HTML | Proibido expressamente. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] |
| Responsividade por constraints | checagem `Platform.isAndroid/Windows` | Flutter recomenda decidir pelo espaço disponível, não pelo tipo de hardware/janela. [CITED: https://docs.flutter.dev/ui/adaptive-responsive/best-practices] |

**Instalação:** nenhum pacote externo novo é necessário. Adicionar somente arquivos de fonte e respectivas licenças ao repositório. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:224-229]

## Auditoria de Legitimidade de Pacotes

Não aplicável: esta recomendação não instala pacote externo. Flutter, Material e `flutter_test` vêm do SDK; `path_provider` já está declarado/resolvido. [VERIFIED: pubspec.yaml:9-24] Se o planejador trocar esta decisão e introduzir um pacote, deverá executar o gate de legitimidade antes do plano de instalação. [ASSUMED]

Para os binários tipográficos, adquirir somente da coleção oficial Google Fonts e versionar também o arquivo de licença da família; o repositório oficial declara que cada diretório de família contém sua licença. [CITED: https://github.com/google/fonts]

## Padrões de Arquitetura

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
      Leitor contínuo (máx. 760)
        | frase ativa/pending |
        v                    v
 auto-scroll condicionado   confirmação
                    |
                    v
 player persistente + painel técnico recolhível
                    |
                    v
 callbacks existentes -> pipeline/audio/RTF/MOS/memória offline
```

O fluxo mantém todas as decisões no tier Flutter e usa callbacks para chegar aos serviços existentes, sem fazer a UI possuir engine, fila ou PCM. [VERIFIED: lib/main.dart:793-820] [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19]

### Estrutura Recomendada

```text
assets/fonts/                    # TTF/OTF + licenças das três famílias [ASSUMED]
lib/ui/
├── app_theme.dart               # tokens semânticos e ThemeData claro/escuro
├── theme_preference.dart        # ThemeMode persistido localmente [ASSUMED]
└── widgets/
    ├── responsive_navigation_shell.dart
    ├── library_view.dart
    ├── settings_view.dart
    ├── reader_page.dart
    ├── reader_document_view.dart
    └── audio_player_control_bar.dart
test/ui/
├── theme_contract_test.dart     # fontes/tokens/tema/persistência [ASSUMED]
├── redesign_widgets_test.dart
├── accessibility_test.dart      # guidelines/semantics/foco [ASSUMED]
└── goldens/                     # biblioteca/leitor, temas e viewports [ASSUMED]
```

Os nomes novos acima são uma recomendação de organização e ainda não existem; o planejador pode ajustá-los mantendo responsabilidades separadas. [ASSUMED]

### Padrão 1: Tokens semânticos como fonte única

**O que:** definir cores, spacing e os quatro papéis tipográficos em uma única camada; widgets consultam `Theme.of(context)`/ThemeExtension e não importam cores claras/escuras fixas. O Material obtém aparência principalmente de `colorScheme` e `textTheme`. [CITED: https://api.flutter.dev/flutter/material/ThemeData-class.html]

**Quando usar:** em todos os widgets da fase. O código atual fixa `AppColors` globais, impedindo paridade de temas. [VERIFIED: lib/ui/app_theme.dart:4-17]

### Padrão 2: Responsividade por constraints e composição compartilhada

**O que:** `LayoutBuilder` decide apenas a composição; os mesmos subwidgets/callbacks alimentam variantes compacta e larga. Flutter diferencia `LayoutBuilder` por fornecer constraints do ponto específico da árvore. [CITED: https://docs.flutter.dev/ui/adaptive-responsive/general]

**Quando usar:** shell, biblioteca, leitor, player e painéis. Preservar os valores verbatim do contrato: `"<600px"`, `"600–899px"`, `"≥900px"`, máximo `"960px"` para biblioteca e `"760px"` para leitura. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-177]

### Padrão 3: Ações independentes do dispositivo de entrada

**O que:** um Intent/Action representa importar, play/pause, fechar seleção e mover frase; toque, menu, botão e atalho invocam a mesma ação. O sistema Flutter separa atalhos, intents e actions para que o binding fique distante da implementação. [CITED: https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts]

**Quando usar:** `Space`, `Escape`, setas e `Ctrl+O`; impedir captura quando `FocusManager.instance.primaryFocus?.context` estiver em um `EditableText`. Eventos de foco são processados antes da entrada de texto e podem impedir a digitação se tratados no ancestral. [CITED: https://docs.flutter.dev/ui/interactivity/focus]

### Padrão 4: Auto-scroll orientado por visibilidade, não por índice

**O que:** manter contexto/chave estável por frase, verificar se o render object saiu do viewport e chamar `Scrollable.ensureVisible` apenas então; gesto manual suspende o movimento até a próxima mudança de frase/comando. `Scrollable.ensureVisible` torna o alvo visível e aceita `Duration.zero`. [CITED: https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html]

**Quando usar:** somente para mudança aceita de frase ativa. Se `MediaQuery.disableAnimationsOf(context)` for verdadeiro, usar duração zero; a API representa pedido da plataforma para reduzir/desabilitar animações. [CITED: https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html]

### Padrão 5: Estado visual explícito e testável

**O que:** modelar importação, engine, leitura, playback, métricas e tema como estados controlados; cada estado gera copy e ação definidas na UI-SPEC. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:183-205]

**Quando usar:** evitar strings ad hoc e flags acopladas. Hoje o card de importação usa `isProcessing`, que também representa síntese. [VERIFIED: lib/ui/widgets/library_view.dart:6-32] [VERIFIED: lib/ui/widgets/library_view.dart:158-214]

### Anti-padrões a Evitar

- **Cores/fontes fixas no widget:** impedem temas e tornam o contrato impossível de auditar; use tokens/ThemeData. [VERIFIED: lib/ui/widgets/library_view.dart:112-155]
- **Recriar recognizers em `build`:** o código atual os descarta e recria em cada rebuild, podendo perder um tap entre pointer down/up. [VERIFIED: lib/ui/widgets/reader_document_view.dart:31-64]
- **Scroll automático contínuo:** conflita com a leitura manual; mover apenas quando a frase sai do viewport. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:150-155]
- **Métrica falsa zero:** ausência deve ser `—`; nunca derivar dado visual sem snapshot válido. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:157-162]
- **Golden único por máquina sem fonte empacotada:** fallbacks variam entre Windows/Android e tornam renderização instável; empacotar fontes antes de capturar goldens. [CITED: https://docs.flutter.dev/cookbook/design/fonts]

## Não Implementar à Mão

| Problema | Não construir | Usar | Por quê |
|---|---|---|---|
| Breakpoints/layout | detector de dispositivo e coordenadas absolutas | `LayoutBuilder`, `Expanded`, `Flexible`, `Wrap`, `ConstrainedBox`, `SafeArea` | Responde à janela real redimensionável. [CITED: https://docs.flutter.dev/ui/adaptive-responsive/general] |
| Tema claro/escuro | ifs de cor em cada widget | `ThemeData`, `ColorScheme`, `TextTheme`, ThemeExtension | Material consome o tema da árvore. [CITED: https://api.flutter.dev/flutter/material/ThemeData-class.html] |
| Atalhos e foco | listener global bruto de teclado | `Actions`, `Shortcuts`, `FocusTraversalGroup`, `FocusableActionDetector` | Preserva escopo de foco, traversal e entrada de texto. [CITED: https://docs.flutter.dev/ui/interactivity/focus] |
| Scroll para frase | cálculo manual fixo por altura de linha | `Scrollable.ensureVisible` + medição do render object | Texto a 200% e imagens mudam alturas. [CITED: https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html] |
| Scrubber | gesture/pointer recognizer customizado | `Slider`/`SliderTheme` | Já atende toque, arraste, mouse, foco e setas. [VERIFIED: lib/ui/widgets/audio_player_control_bar.dart:62-85] |
| Acessibilidade automatizada | checker próprio de contraste/alvo | `meetsGuideline(...)` do `flutter_test` | API oficial cobre target, rótulo e contraste. [CITED: https://docs.flutter.dev/ui/accessibility/accessibility-testing] |

**Insight:** o trabalho desta fase é tematizar e compor capacidades nativas do Flutter; soluções customizadas só se justificam para a borda tracejada, carimbo e sublinhado ondulado editoriais, sempre com semantics e testes. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:137-162]

## Exemplos de Código

### Tema claro/escuro com escolha do sistema

Valores verbatim exigidos: `Sistema`, `Claro`, `Escuro`; a API oficial define `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:101-105] [CITED: https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html]

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: selectedThemeMode,
  home: const PoCNeuralHomePage(),
)
```

O exemplo mostra apenas o wiring oficial; `selectedThemeMode` deve vir de estado persistido e não pode recriar pipeline/player. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:101-105]

### Declaração local de fontes

Valores verbatim exigidos: famílias `Spectral`, `Archivo`, `Space Mono`, pesos `400` e `600`. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:28-39] [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:61-74]

```yaml
flutter:
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
          weight: 400
        - asset: assets/fonts/Spectral-SemiBold.ttf
          weight: 600
```

Os filenames são uma proposta e precisam corresponder aos binários realmente adquiridos; confirmar antes de bloquear o plano. [ASSUMED] Flutter exige paths relativos e declaração explícita de pesos. [CITED: https://docs.flutter.dev/cookbook/design/fonts]

### Breakpoint e limites de legibilidade

Valores verbatim do contrato: troca em `900px`, biblioteca `960px`, leitura `760px`. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-177]

```dart
const wideBreakpoint = 900.0;
const libraryMaxWidth = 960.0;
const readerMaxWidth = 760.0;

LayoutBuilder(
  builder: (context, constraints) => constraints.maxWidth >= wideBreakpoint
      ? wideLayout
      : compactLayout,
)
```

### Movimento reduzido no auto-scroll

Valor verbatim do contrato: transições `não excedem 200ms`; movimento reduzido não anima scroll. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
await Scrollable.ensureVisible(
  sentenceContext,
  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
);
```

A API oficial documenta `disableAnimationsOf` e `Scrollable.ensureVisible`; o gatilho adicional “somente fora do viewport” deve ser testado pelo widget. [CITED: https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html] [CITED: https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html]

## Armadilhas Comuns

### 1. Tratar o plano 14 executado como fidelidade concluída

**Falha:** o shell responsivo existe, mas o design system ainda é o anterior. [VERIFIED: lib/ui/app_theme.dart:3-17]  
**Como evitar:** o novo plano deve ter critérios por token, tipografia, tema, composição e golden, não “layout responsivo” genérico. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:28-74]

### 2. Capturar goldens antes de empacotar fontes

**Falha:** fallback local produz métricas diferentes entre plataformas. [CITED: https://docs.flutter.dev/cookbook/design/fonts]  
**Como evitar:** fontes + pubspec + teste de resolução das famílias devem ser Wave 0 da UI.

### 3. Quebrar texto a 200%

**Falha:** `Row` com status/contadores ou player fixo estoura; o status atual está em uma única `Row`. [VERIFIED: lib/ui/widgets/reader_page.dart:342-366]  
**Como evitar:** `Wrap`, `Flexible`, scroll vertical em altura baixa e testes com `TextScaler.linear(2.0)`. O `textScaler` reflete preferência do sistema. [CITED: https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html]

### 4. Atalho impedir digitação

**Falha:** Shortcuts/Focus processam a tecla antes do campo. [CITED: https://docs.flutter.dev/ui/interactivity/focus]  
**Como evitar:** não tratar Space/setas/Ctrl+O quando o foco primário está em `EditableText`; teste específico no campo de busca.

### 5. Auto-scroll disputar com gesto manual

**Falha:** acompanhar cada rebuild remove controle do usuário. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:150-155]  
**Como evitar:** detectar `UserScrollNotification`, suspender até próxima mudança de frase/comando e só garantir visibilidade se fora do viewport.

### 6. Usar cor como único sinal

**Falha:** ativo e pendente ficam indistinguíveis para baixa visão/leitor de tela. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:78-105]  
**Como evitar:** ativo = peso + ondulado + semantics “frase atual”; pendente = colchetes/borda + semantics “seleção pendente”.

### 7. Alterar pipeline durante o redesign

**Falha:** acopla risco funcional ao visual e viola decisão bloqueada. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19]  
**Como evitar:** UI recebe snapshots/callbacks; planos 14-02–14-06 continuam donos de persistência, streaming e telemetria.

## Impacto nos Planos Existentes

| Plano | Direção prescritiva |
|---|---|
| 14-PLAN executado | Não aceitar como fechamento visual; registrar como base estrutural e criar plano corretivo de fundação de UI antes das superfícies. [VERIFIED: .planning/phases/14-ui-redesign/14-PLAN.md] |
| 14-02 | Manter foco em identidade/storage; não misturar redesign. Tema persistido deve usar seam separado e não alterar registros de livro. [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] |
| 14-03 | Manter foco em ownership/cancelamento; expor apenas estado estável para a UI. [VERIFIED: .planning/phases/14-ui-redesign/14-03-PLAN.md] |
| 14-04 | Ampliar LibraryView/Settings: estados exatos, microcopy, confirmação destrutiva, cards editoriais, busca controlada e seletor de tema. [VERIFIED: .planning/phases/14-ui-redesign/14-04-PLAN.md] |
| 14-05/14-06 | Manter modelo de telemetria sem PCM; ampliar ReaderPage/Player para painel técnico recolhível, `—` ausente, safe area, MOS/report honestos e composição responsiva tematizada. [VERIFIED: .planning/phases/14-ui-redesign/14-05-PLAN.md] [VERIFIED: .planning/phases/14-ui-redesign/14-06-PLAN.md] |
| 14-07 | Ampliar além de gestures: leitor visual aprovado, auto-scroll, atalhos/foco/semantics, matriz de temas/viewports/text scale, goldens e UAT Android/Windows. [VERIFIED: .planning/phases/14-ui-redesign/14-07-PLAN.md] |

Ordem recomendada: **Fundação UI → 14-02/14-03 em paralelo funcional → 14-04 biblioteca/ajustes → 14-05/14-06 telemetria/player → 14-07 leitor/validação/UAT**. [ASSUMED]

## Estado da Arte

| Abordagem antiga no projeto | Abordagem exigida agora | Impacto |
|---|---|---|
| Tema escuro único e cores globais | `theme`, `darkTheme`, `themeMode` e tokens semânticos | Paridade claro/escuro/sistema. [CITED: https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html] |
| Fontes declaradas apenas por nome/fallback | Fontes TTF/OTF empacotadas no pubspec com peso explícito | Fidelidade e goldens determinísticos. [CITED: https://docs.flutter.dev/cookbook/design/fonts] |
| CallbackShortcuts direto | Actions/Shortcuts + traversal/foco editável protegido | Atalhos desktop sem quebrar busca. [CITED: https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts] |
| Teste de presença em dois tamanhos | Matriz widget + golden + semantics + guidelines | Verifica fidelidade, overflow e acessibilidade. [CITED: https://docs.flutter.dev/ui/accessibility/accessibility-testing] |

**Deprecado no repositório:** `withOpacity` em `sentence_highlight_view.dart` foi reportado como deprecated por `dart analyze`; usar `.withValues()` se esse widget continuar em uso. [VERIFIED: dart analyze 2026-08-03]

## Log de Suposições

| # | Alegação assumida | Seção | Risco se errada |
|---|---|---|---|
| A1 | Os filenames `Spectral-Regular.ttf`/`Spectral-SemiBold.ttf` serão os nomes dos assets finais. | Exemplos | Pubspec falha ou aponta para arquivos inexistentes; confirmar após aquisição. |
| A2 | Novos arquivos `theme_preference.dart`, `theme_contract_test.dart`, `accessibility_test.dart` e diretório `goldens/` são a melhor decomposição. | Estrutura | O planner pode preferir nomes/organização existentes; responsabilidade é mais importante que nome. |
| A3 | A ordem de waves proposta é a melhor forma de atualizar os planos. | Impacto nos planos | Dependências reais/ownership podem exigir divisão diferente, mas fundação deve preceder goldens. |
| A4 | Qualquer pacote futuro deve passar gate de legitimidade. | Auditoria | Só se aplica se o planejador decidir adicionar dependência externa. |
| A5 | Os comandos rápidos e nomes dos novos arquivos de teste serão exatamente os propostos. | Validação | O planner pode consolidar arquivos ou mudar `--plain-name`; preservar a cobertura, não o nome. |
| A6 | Um único host/engine canônico será usado para atualizar goldens. | Perguntas abertas | Sem decisão, diferenças de rasterização podem gerar ruído entre ambientes. |
| A7 | Harnesses, factories de fixtures e a taxa de amostragem proposta serão adotados. | Validação/Wave 0 | Outra infraestrutura pode ser igualmente válida, desde que execute a mesma matriz. |

## Perguntas em Aberto

1. **Quais binários exatos das fontes serão versionados?**
   - Sabemos: famílias e pesos 400/600 são bloqueados; nenhum arquivo está presente. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:28-39] [VERIFIED: workspace font asset audit]
   - Incerto: estáticos versus variable fonts e filenames finais.
   - Recomendação: usar TTF/OTF estáticos 400/600 da coleção oficial e versionar licença; validar glyphs pt-BR antes dos goldens. [CITED: https://github.com/google/fonts]

2. **O plano corretivo será um novo número ou reabertura do 14-PLAN?**
   - Sabemos: `14-PLAN.md` está marcado executado e os planos 02–07 têm responsabilidades funcionais já definidas. [VERIFIED: .planning/ROADMAP.md]
   - Incerto: convenção operacional preferida pelo orquestrador.
   - Recomendação: novo plano corretivo de fundação, evitando reescrever histórico executado. [ASSUMED]

3. **Goldens serão aprovados em qual host canônico?**
   - Sabemos: `matchesGoldenFile` usa comparação de imagem de referência e o renderer pode variar por host. [CITED: https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html]
   - Incerto: CI/Windows local como autoridade.
   - Recomendação: escolher um único host/engine para atualização dos goldens e usar widgets/semantics para invariantes cross-platform. [ASSUMED]

## Disponibilidade do Ambiente

| Dependência | Requerida por | Disponível | Versão | Fallback |
|---|---|---:|---:|---|
| Flutter SDK | build/análise/testes | ✓ | 3.44.8 stable | — [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-13] |
| Dart SDK | análise | ✓ | 3.12.2 | — [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:11-13] |
| Android shell | UAT Android | ✓ no repositório | Flutter Gradle plugin e namespace existentes | dispositivo físico continua obrigatório. [VERIFIED: android/app/build.gradle.kts:1-25] |
| Windows shell | UAT Windows | ✓ no repositório | CMake mínimo 3.14; binário `tcc_tts_neural` | máquina Windows nativa continua obrigatória. [VERIFIED: windows/CMakeLists.txt:1-11] |
| Fontes locais | fidelidade/goldens | ✗ | — | bloqueador da fundação visual; fallbacks não satisfazem entrega final. [VERIFIED: workspace font asset audit] |

`dart analyze lib/ui lib/main.dart test/ui/redesign_widgets_test.dart test/ui/audio_player_widget_test.dart` concluiu com somente 2 infos de depreciação em `sentence_highlight_view.dart`. [VERIFIED: command run 2026-08-03] O comando Flutter ficou bloqueado enquanto havia processos Flutter/Dart concorrentes; os testes não foram usados como evidência de aprovação nesta pesquisa. [VERIFIED: environment process audit 2026-08-03]

## Arquitetura de Validação

### Framework de Teste

| Propriedade | Valor |
|---|---|
| Framework | `flutter_test` do Flutter SDK 3.44.8 [VERIFIED: pubspec.yaml:21-24] |
| Configuração | `analysis_options.yaml`; não há config golden dedicada observada. [VERIFIED: workspace root audit] |
| Comando rápido | `flutter test --no-pub test/ui/theme_contract_test.dart test/ui/redesign_widgets_test.dart` [ASSUMED] |
| Suíte completa | `flutter test --no-pub` [ASSUMED] |

### Contrato → Mapa de Testes

| Contrato | Comportamento | Tipo | Comando automatizado | Existe? |
|---|---|---|---|---|
| Tema/fontes | famílias exatas, quatro tamanhos, dois pesos, temas claro/escuro/sistema persistido | widget/unit | `flutter test --no-pub test/ui/theme_contract_test.dart` | ❌ Wave 0 [ASSUMED] |
| Navegação | barra <900; rail >=900; 899/900; foco inicial | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name navigation` | ⚠️ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:18-61] |
| Biblioteca | 0/1/muitos, busca vazia, títulos longos, todos estados de importação, delete | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name biblioteca` | ⚠️ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:63-140] |
| Leitor | texto/imagem, vazio/parcial/erro, ativo/pending, auto-scroll/manual, retomada | widget/golden | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name leitor` | ⚠️ parcial [VERIFIED: test/ui/redesign_widgets_test.dart:142-217] |
| Player/métricas | todos estados, scrubber teclado/mouse/toque, MOS/report, painel recolhível, `—` ausente | widget/integration | `flutter test --no-pub test/ui/audio_player_widget_test.dart test/ui/telemetry_flow_test.dart` | ⚠️ parcial; telemetry_flow ainda planejado [VERIFIED: test/ui/audio_player_widget_test.dart:10-125] |
| Atalhos/foco | Space/Escape/setas/Ctrl+O; TextField não captura | widget | `flutter test --no-pub test/ui/accessibility_test.dart --plain-name atalhos` | ❌ Wave 0 [ASSUMED] |
| Acessibilidade | targets, labels, contraste, text scale 200%, reduced motion | guideline/widget | `flutter test --no-pub test/ui/accessibility_test.dart` | ❌ Wave 0 [ASSUMED] |
| Fidelidade | biblioteca/leitor 390×844, 800×1280, 1440×900 em claro/escuro | golden | `flutter test --no-pub test/ui/golden_test.dart` | ❌ Wave 0 [ASSUMED] |
| Robustez estreita | 320 px e janela baixa sem overflow | widget | `flutter test --no-pub test/ui/redesign_widgets_test.dart --plain-name overflow` | ❌ Wave 0 [ASSUMED] |

### Matriz mínima obrigatória

| Viewport | Claro | Escuro | Texto 200% | Estado crítico |
|---|---:|---:|---:|---|
| 320×568 | widget | widget | ✓ | player wrap + títulos longos [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-179] |
| 390×844 | golden | golden | ✓ | biblioteca e leitor [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 800×1280 | golden | golden | ✓ | tablet/barra inferior [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 1440×900 | golden | golden | ✓ | rail + leitor/player lateral [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220] |
| 899×900 / 900×900 | widget | widget | — | limite exato do breakpoint [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:166-179] |

### Taxa de Amostragem

- **Por commit de tarefa:** teste do arquivo tocado + `dart analyze` dos arquivos modificados. [ASSUMED]
- **Por merge de wave:** suíte UI inteira em temas claro/escuro. [ASSUMED]
- **Gate da fase:** `flutter test --no-pub`, análise sem erros, goldens aprovados, guidelines de acessibilidade e UAT Android/Windows. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:214-220]

### Gaps Wave 0

- [ ] adquirir e versionar fontes/licenças; declarar no pubspec; validar pesos 400/600. [VERIFIED: workspace font asset audit]
- [ ] criar harness de tema e preferência persistida. [ASSUMED]
- [ ] criar factories de fixtures para biblioteca/leitor/player sem duplicar dezenas de callbacks. [ASSUMED]
- [ ] criar helper de viewport + `TextScaler.linear(2.0)` + reset seguro. [CITED: https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html]
- [ ] criar baselines golden canônicos somente após fontes/tokens estabilizarem. [CITED: https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html]
- [ ] adicionar `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline` e `textContrastGuideline`. [CITED: https://docs.flutter.dev/ui/accessibility/accessibility-testing]

## Domínio de Segurança

### Categorias ASVS Aplicáveis

| Categoria ASVS | Aplica | Controle padrão |
|---|---|---|
| V2 Autenticação | não | App offline sem autenticação no escopo. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |
| V3 Sessão | não | Não há sessão remota no escopo. [VERIFIED: .planning/phases/14-ui-redesign/14-CONTEXT.md:15-19] |
| V4 Controle de acesso | não | Dados ficam no storage privado da aplicação; redesign não muda boundary. [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] |
| V5 Validação de entrada | sim | Picker/importador continuam validando EPUB; UI só mapeia erro para copy segura. [VERIFIED: .planning/phases/14-ui-redesign/14-04-PLAN.md] |
| V6 Criptografia | sim, somente integridade de identidade | SHA-256 via pacote existente no Plano 14-02; nunca implementar hash manual. [VERIFIED: pubspec.yaml:18-19] [VERIFIED: .planning/phases/14-ui-redesign/14-02-PLAN.md] |

### Padrões de Ameaça do Stack

| Padrão | STRIDE | Mitigação |
|---|---|---|
| Atalho dispara importação enquanto usuário digita | Tampering/DoS | Ignorar shortcut quando foco estiver em `EditableText`; single-flight do Plano 14-04. [CITED: https://docs.flutter.dev/ui/interactivity/focus] |
| Mensagem expõe path/exceção | Information Disclosure | Copy principal segura; detalhes somente área técnica expansível. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:123-133] |
| Web/font asset remoto quebra offline | Information Disclosure/DoS | Nenhum WebView/recurso remoto; assets empacotados. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md:20-24] |
| Estado visual stale dispara áudio antigo | Tampering | Ownership/generation do Plano 14-03; UI não cria stream próprio. [VERIFIED: .planning/phases/14-ui-redesign/14-03-PLAN.md] |
| Telemetria prolonga vida do PCM | DoS | Snapshot somente de escalares; planos 14-05/06 mantêm fila proprietária do áudio. [VERIFIED: .planning/phases/14-ui-redesign/14-05-PLAN.md] |

## Fontes

### Primárias (ALTA confiança local)

- `.planning/phases/14-ui-redesign/14-CONTEXT.md` — decisões bloqueadas.
- `.planning/phases/14-ui-redesign/14-UI-SPEC.md` — contrato aprovado completo.
- `lib/ui/app_theme.dart`, `lib/ui/widgets/*`, `lib/main.dart`, `test/ui/*`, `pubspec.yaml`, `pubspec.lock` — estado real do código aberto nesta sessão.
- `C:/Users/55759/flutter/bin/cache/flutter.version.json` — versão local do SDK.

### Secundárias (MÉDIA confiança; documentação oficial consultada via WebSearch)

- https://docs.flutter.dev/ui/adaptive-responsive/general — LayoutBuilder e composição adaptativa.
- https://docs.flutter.dev/ui/adaptive-responsive/best-practices — espaço disponível, não tipo de hardware.
- https://docs.flutter.dev/cookbook/design/fonts — fontes locais, formatos e pesos.
- https://api.flutter.dev/flutter/material/MaterialApp/themeMode.html — ThemeMode.
- https://docs.flutter.dev/ui/interactivity/focus — foco, traversal e conflito com entrada de texto.
- https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts — Actions/Shortcuts.
- https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html — visibilidade da frase.
- https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html — movimento reduzido.
- https://docs.flutter.dev/ui/accessibility/accessibility-testing — guidelines automatizadas.
- https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html — golden testing.
- https://github.com/google/fonts — fonte/licenças das famílias.

### Terciárias (BAIXA confiança)

- Nenhuma fonte web não oficial foi usada; decisões ainda não verificadas estão marcadas `[ASSUMED]`.

## Metadados

**Quebra de confiança:**
- Stack padrão: ALTA — SDK e dependências verificados localmente; documentação oficial atual reflete Flutter 3.44.7 e o SDK local é 3.44.8. [VERIFIED: C:/Users/55759/flutter/bin/cache/flutter.version.json:2-13] [CITED: https://docs.flutter.dev/ui/adaptive-responsive/general]
- Arquitetura: ALTA — deriva do contrato aprovado e dos widgets reais abertos nesta sessão. [VERIFIED: .planning/phases/14-ui-redesign/14-UI-SPEC.md]
- Armadilhas: ALTA para gaps locais; MÉDIA para recomendações de APIs externas consultadas via WebSearch oficial.
- Validação: ALTA para a matriz obrigatória; MÉDIA para filenames/organização dos novos testes.

**Data da pesquisa:** 2026-08-03  
**Válida até:** 2026-09-02 para o contrato local; revalidar documentação/SDK se Flutter for atualizado.
