import 'package:flutter/material.dart';

/// Design system editorial inspirado em design_mockup.html.
class AppColors {
  static const ink = Color(0xFF12151C);
  static const ink2 = Color(0xFF1B1F29);
  static const ink3 = Color(0xFF242938);
  static const paper = Color(0xFFEDE7D6);
  static const paperDim = Color(0xFF9CA0AC);
  static const paperFaint = Color(0xFF5C6072);
  static const amber = Color(0xFFE3A452);
  static const amberDim = Color(0xFF4A3B27);
  static const teal = Color(0xFF4FA9A6);
  static const tealDim = Color(0xFF20393B);
  static const coral = Color(0xFFE2694F);
  static const line = Color(0xFF2B303F);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadii {
  static const sm = 7.0;
  static const md = 14.0;
  static const lg = 20.0;
}

class AppBreakpoints {
  static const compact = 700.0;
  static const wide = 900.0;
}

class AppTextStyles {
  static const reading = TextStyle(
    color: AppColors.paperDim,
    fontFamily: 'Literata',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 17,
    height: 1.75,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.paper,
    fontFamily: 'Literata',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const metric = TextStyle(
    color: AppColors.paperFaint,
    fontFamily: 'JetBrains Mono',
    fontFamilyFallback: ['Consolas', 'monospace'],
    fontSize: 11,
  );
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.dark,
      surface: AppColors.ink2,
      error: AppColors.coral,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: AppColors.amber,
        onPrimary: AppColors.ink,
        secondary: AppColors.teal,
        onSecondary: AppColors.ink,
        surface: AppColors.ink2,
        onSurface: AppColors.paper,
        outline: AppColors.line,
        error: AppColors.coral,
      ),
      scaffoldBackgroundColor: AppColors.ink,
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'sans-serif'],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.paper, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.paperDim),
        titleLarge: TextStyle(
          color: AppColors.paper,
          fontFamily: 'Literata',
          fontFamilyFallback: ['Georgia', 'serif'],
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.ink2,
        indicatorColor: AppColors.amberDim,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.paperDim, fontSize: 11),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.ink2,
        indicatorColor: AppColors.amberDim,
        selectedIconTheme: IconThemeData(color: AppColors.amber),
        unselectedIconTheme: IconThemeData(color: AppColors.paperFaint),
        selectedLabelTextStyle: TextStyle(color: AppColors.amber, fontSize: 11),
        unselectedLabelTextStyle:
            TextStyle(color: AppColors.paperFaint, fontSize: 11),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.ink2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
