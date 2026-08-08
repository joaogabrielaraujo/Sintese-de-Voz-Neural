import 'package:flutter/material.dart';

/// Enumeração das 4 paletas de cores do aplicativo (Padrão + 3 Temas de vozlume_temas.html).
enum AppThemePalette {
  padrao('Padrão'),
  botanico('Botânico'),
  carmim('Carmim'),
  marinha('Marinha');

  final String label;
  const AppThemePalette(this.label);

  static const arquivo = carmim;
}

/// Palette tokens para os temas editoriais do VozLume.
class AppPaletteTokens {
  final Color paper;
  final Color card;
  final Color cardElevated;
  final Color signal;
  final Color signalVar;
  final Color grifo;
  final Color moss;
  final Color text;
  final Color textSoft;
  final Color textWeak;
  final Color line;
  final Color destructive;

  const AppPaletteTokens({
    required this.paper,
    required this.card,
    required this.cardElevated,
    required this.signal,
    required this.signalVar,
    required this.grifo,
    required this.moss,
    required this.text,
    required this.textSoft,
    required this.textWeak,
    required this.line,
    required this.destructive,
  });
}

/// Tokens e constantes do design system editorial (Padrão, Botânico, Arquivo e Marinha).
class AppColors {
  // ─── TEMA PADRÃO (Editorial Original) ───
  static const lightPaper = Color(0xFFE7DFC6);
  static const lightCard = Color(0xFFDED2AE);
  static const lightCardElevated = Color(0xFFD6C99E);
  static const lightSignal = Color(0xFF2E5578);
  static const lightSignalVar = Color(0xFF3F6788);
  static const lightGrifo = Color(0xFFA8402C);
  static const lightMoss = Color(0xFF4B5D3A);
  static const lightText = Color(0xFF242229);
  static const lightTextSoft = Color(0xFF6B6355);
  static const lightTextWeak = Color(0xFF948C78);
  static const lightLine = Color(0x29242229);
  static const lightDestructive = Color(0xFF8C2F2F);

  static const darkSlate = Color(0xFF262A22);
  static const darkCard = Color(0xFF2E332A);
  static const darkCardElevated = Color(0xFF363C31);
  static const darkSignal = Color(0xFF6E9BC1);
  static const darkSignalVar = Color(0xFF82ABD1);
  static const darkGrifo = Color(0xFFC25A42);
  static const darkMoss = Color(0xFF4B5D3A);
  static const darkText = Color(0xFFE7DFC6);
  static const darkTextSoft = Color(0xFFC2B9A0);
  static const darkTextWeak = Color(0xFF8C8778);
  static const darkLine = Color(0x29E7DFC6);
  static const darkDestructive = Color(0xFFD9534F);

  // ─── TEMA BOTÂNICO ───
  static const botanicoLight = AppPaletteTokens(
    paper: Color(0xFFE6E9DF),
    card: Color(0xFFD9DDD0),
    cardElevated: Color(0xFFCDD2C2),
    signal: Color(0xFF3B6B4A),
    signalVar: Color(0xFF4F8260),
    grifo: Color(0xFF4B7A38),
    moss: Color(0xFF6B8040),
    text: Color(0xFF1E2318),
    textSoft: Color(0xFF5A6150),
    textWeak: Color(0xFF8A9278),
    line: Color(0x291E2318),
    destructive: Color(0xFF8C2F2F),
  );

  static const botanicoDark = AppPaletteTokens(
    paper: Color(0xFF1E2219),
    card: Color(0xFF242920),
    cardElevated: Color(0xFF2C3226),
    signal: Color(0xFF7DB88A),
    signalVar: Color(0xFF90C89A),
    grifo: Color(0xFF82B86A),
    moss: Color(0xFFA0B870),
    text: Color(0xFFDCE4D0),
    textSoft: Color(0xFFA0AC8E),
    textWeak: Color(0xFF6B7860),
    line: Color(0x21DCE4D0),
    destructive: Color(0xFFD9534F),
  );

  // ─── TEMA ARQUIVO ───
  static const arquivoLight = AppPaletteTokens(
    paper: Color(0xFFEEE0E0),
    card: Color(0xFFE3D0D0),
    cardElevated: Color(0xFFD8C0C0),
    signal: Color(0xFF8B4558),
    signalVar: Color(0xFFA05068),
    grifo: Color(0xFFB83060),
    moss: Color(0xFF6B5040),
    text: Color(0xFF28181A),
    textSoft: Color(0xFF6A4A4E),
    textWeak: Color(0xFF9A7878),
    line: Color(0x2928181A),
    destructive: Color(0xFF8C2F2F),
  );

  static const arquivoDark = AppPaletteTokens(
    paper: Color(0xFF241A1C),
    card: Color(0xFF2E2022),
    cardElevated: Color(0xFF38262A),
    signal: Color(0xFFD47898),
    signalVar: Color(0xFFE490AA),
    grifo: Color(0xFFE06090),
    moss: Color(0xFFC09070),
    text: Color(0xFFEDD8D8),
    textSoft: Color(0xFFB09090),
    textWeak: Color(0xFF7A6060),
    line: Color(0x21EDD8D8),
    destructive: Color(0xFFD9534F),
  );

  // ─── TEMA MARINHA ───
  static const marinhaLight = AppPaletteTokens(
    paper: Color(0xFFDDE2EC),
    card: Color(0xFFCDD4E2),
    cardElevated: Color(0xFFBDC6D8),
    signal: Color(0xFF1E3A72),
    signalVar: Color(0xFF284888),
    grifo: Color(0xFF2444A8),
    moss: Color(0xFF7A4830),
    text: Color(0xFF181C28),
    textSoft: Color(0xFF404C68),
    textWeak: Color(0xFF7880A0),
    line: Color(0x29181C28),
    destructive: Color(0xFF8C2F2F),
  );

  static const marinhaDark = AppPaletteTokens(
    paper: Color(0xFF181C26),
    card: Color(0xFF1E2430),
    cardElevated: Color(0xFF262E3C),
    signal: Color(0xFF7090E0),
    signalVar: Color(0xFF88A8F0),
    grifo: Color(0xFF6888E8),
    moss: Color(0xFFD08050),
    text: Color(0xFFD8DCF0),
    textSoft: Color(0xFF8890B8),
    textWeak: Color(0xFF5A6080),
    line: Color(0x21D8DCF0),
    destructive: Color(0xFFD9534F),
  );

  /// Retorna os tokens de cores diurnas para a paleta selecionada.
  static AppPaletteTokens getLightTokens(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.botanico:
        return botanicoLight;
      case AppThemePalette.arquivo:
        return arquivoLight;
      case AppThemePalette.marinha:
        return marinhaLight;
      case AppThemePalette.padrao:
      default:
        return const AppPaletteTokens(
          paper: lightPaper,
          card: lightCard,
          cardElevated: lightCardElevated,
          signal: lightSignal,
          signalVar: lightSignalVar,
          grifo: lightGrifo,
          moss: lightMoss,
          text: lightText,
          textSoft: lightTextSoft,
          textWeak: lightTextWeak,
          line: lightLine,
          destructive: lightDestructive,
        );
    }
  }

  /// Retorna os tokens de cores noturnas para a paleta selecionada.
  static AppPaletteTokens getDarkTokens(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.botanico:
        return botanicoDark;
      case AppThemePalette.arquivo:
        return arquivoDark;
      case AppThemePalette.marinha:
        return marinhaDark;
      case AppThemePalette.padrao:
      default:
        return const AppPaletteTokens(
          paper: darkSlate,
          card: darkCard,
          cardElevated: darkCardElevated,
          signal: darkSignal,
          signalVar: darkSignalVar,
          grifo: darkGrifo,
          moss: darkMoss,
          text: darkText,
          textSoft: darkTextSoft,
          textWeak: darkTextWeak,
          line: darkLine,
          destructive: darkDestructive,
        );
    }
  }
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

class AppRadii {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
}

class AppBreakpoints {
  static const compact = 700.0;
  static const wide = 900.0;
}

/// Extensão customizada de tema para expor os papéis editoriais aprovados
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color grifo;
  final Color moss;
  final Color card;
  final Color cardElevated;
  final Color textSoft;
  final Color textWeak;

  const AppThemeExtension({
    required this.grifo,
    required this.moss,
    required this.card,
    required this.cardElevated,
    required this.textSoft,
    required this.textWeak,
  });

  @override
  AppThemeExtension copyWith({
    Color? grifo,
    Color? moss,
    Color? card,
    Color? cardElevated,
    Color? textSoft,
    Color? textWeak,
  }) {
    return AppThemeExtension(
      grifo: grifo ?? this.grifo,
      moss: moss ?? this.moss,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      textSoft: textSoft ?? this.textSoft,
      textWeak: textWeak ?? this.textWeak,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      grifo: Color.lerp(grifo, other.grifo, t)!,
      moss: Color.lerp(moss, other.moss, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      textWeak: Color.lerp(textWeak, other.textWeak, t)!,
    );
  }
}

class AppTextStyles {
  static const statusMono = TextStyle(
    fontFamily: 'Space Mono',
    fontFamilyFallback: ['Consolas', 'monospace'],
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const uiBody = TextStyle(
    fontFamily: 'Archivo',
    fontFamilyFallback: ['Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const epubReading = TextStyle(
    fontFamily: 'Spectral',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Spectral',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const brandDisplay = TextStyle(
    fontFamily: 'Spectral',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

class AppTheme {
  static ThemeData light({AppThemePalette palette = AppThemePalette.padrao}) {
    final tokens = AppColors.getLightTokens(palette);

    final scheme = ColorScheme.light(
      surface: tokens.paper,
      onSurface: tokens.text,
      primary: tokens.signal,
      onPrimary: Colors.white,
      secondary: tokens.signalVar,
      outline: tokens.line,
      error: tokens.destructive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.paper,
      fontFamily: 'Archivo',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      extensions: [
        AppThemeExtension(
          grifo: tokens.grifo,
          moss: tokens.moss,
          card: tokens.card,
          cardElevated: tokens.cardElevated,
          textSoft: tokens.textSoft,
          textWeak: tokens.textWeak,
        ),
      ],
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.uiBody,
        titleMedium: AppTextStyles.sectionTitle,
        titleLarge: AppTextStyles.brandDisplay,
        labelSmall: AppTextStyles.statusMono,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.paper,
        foregroundColor: tokens.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: tokens.line),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.card,
        indicatorColor: tokens.signal.withAlpha(40),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.uiBody.copyWith(fontSize: 12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.card,
        indicatorColor: tokens.signal.withAlpha(40),
        selectedIconTheme: IconThemeData(color: tokens.signal),
        unselectedIconTheme: IconThemeData(color: tokens.textSoft),
        selectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.signal),
        unselectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, color: tokens.textSoft),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
    );
  }

  static ThemeData dark({AppThemePalette palette = AppThemePalette.padrao}) {
    final tokens = AppColors.getDarkTokens(palette);

    final scheme = ColorScheme.dark(
      surface: tokens.paper,
      onSurface: tokens.text,
      primary: tokens.signal,
      onPrimary: tokens.paper,
      secondary: tokens.signalVar,
      outline: tokens.line,
      error: tokens.destructive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.paper,
      fontFamily: 'Archivo',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      extensions: [
        AppThemeExtension(
          grifo: tokens.grifo,
          moss: tokens.moss,
          card: tokens.card,
          cardElevated: tokens.cardElevated,
          textSoft: tokens.textSoft,
          textWeak: tokens.textWeak,
        ),
      ],
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.uiBody,
        titleMedium: AppTextStyles.sectionTitle,
        titleLarge: AppTextStyles.brandDisplay,
        labelSmall: AppTextStyles.statusMono,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.paper,
        foregroundColor: tokens.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: tokens.line),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.card,
        indicatorColor: tokens.signal.withAlpha(40),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.uiBody.copyWith(fontSize: 12, color: tokens.text),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.card,
        indicatorColor: tokens.signal.withAlpha(40),
        selectedIconTheme: IconThemeData(color: tokens.signal),
        unselectedIconTheme: IconThemeData(color: tokens.textSoft),
        selectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.signal),
        unselectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, color: tokens.textSoft),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
    );
  }
}
