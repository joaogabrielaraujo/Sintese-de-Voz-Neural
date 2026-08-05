import 'package:flutter/material.dart';
import 'package:tcc_tts_neural/ui/app_theme.dart';

class GoldenHarness {
  static Widget buildHarness({
    required Widget child,
    required Size size,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: 1.0,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
