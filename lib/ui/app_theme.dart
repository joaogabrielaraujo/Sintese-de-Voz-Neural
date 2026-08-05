import 'package:flutter/material.dart';

/// Tokens e estension do design system editorial (vozlume_redesign / 14-UI-SPEC.md)
class AppColors {
  // Light palette
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

  // Dark palette
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
  static ThemeData light() {
    final scheme = ColorScheme.light(
      surface: AppColors.lightPaper,
      onSurface: AppColors.lightText,
      primary: AppColors.lightSignal,
      onPrimary: Colors.white,
      secondary: AppColors.lightSignalVar,
      outline: AppColors.lightLine,
      error: AppColors.lightDestructive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightPaper,
      fontFamily: 'Archivo',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      extensions: const [
        AppThemeExtension(
          grifo: AppColors.lightGrifo,
          moss: AppColors.lightMoss,
          card: AppColors.lightCard,
          cardElevated: AppColors.lightCardElevated,
          textSoft: AppColors.lightTextSoft,
          textWeak: AppColors.lightTextWeak,
        ),
      ],
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.uiBody,
        titleMedium: AppTextStyles.sectionTitle,
        titleLarge: AppTextStyles.brandDisplay,
        labelSmall: AppTextStyles.statusMono,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPaper,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightLine),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.lightSignal.withAlpha(40),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.uiBody.copyWith(fontSize: 12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.lightSignal.withAlpha(40),
        selectedIconTheme: const IconThemeData(color: AppColors.lightSignal),
        unselectedIconTheme: const IconThemeData(color: AppColors.lightTextSoft),
        selectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightSignal),
        unselectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, color: AppColors.lightTextSoft),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      surface: AppColors.darkSlate,
      onSurface: AppColors.darkText,
      primary: AppColors.darkSignal,
      onPrimary: AppColors.darkSlate,
      secondary: AppColors.darkSignalVar,
      outline: AppColors.darkLine,
      error: AppColors.darkDestructive,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkSlate,
      fontFamily: 'Archivo',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      extensions: const [
        AppThemeExtension(
          grifo: AppColors.darkGrifo,
          moss: AppColors.darkMoss,
          card: AppColors.darkCard,
          cardElevated: AppColors.darkCardElevated,
          textSoft: AppColors.darkTextSoft,
          textWeak: AppColors.darkTextWeak,
        ),
      ],
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.uiBody,
        titleMedium: AppTextStyles.sectionTitle,
        titleLarge: AppTextStyles.brandDisplay,
        labelSmall: AppTextStyles.statusMono,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSlate,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkLine),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.darkSignal.withAlpha(40),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextStyles.uiBody.copyWith(fontSize: 12, color: AppColors.darkText),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.darkSignal.withAlpha(40),
        selectedIconTheme: const IconThemeData(color: AppColors.darkSignal),
        unselectedIconTheme: const IconThemeData(color: AppColors.darkTextSoft),
        selectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkSignal),
        unselectedLabelTextStyle: AppTextStyles.uiBody.copyWith(fontSize: 12, color: AppColors.darkTextSoft),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
    );
  }
}
