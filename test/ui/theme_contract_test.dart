import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/ui/app_theme.dart';
import 'package:tcc_tts_neural/ui/theme_preference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('native theme tracer', () {
    test('font families, weights and sizes match 14-UI-SPEC contract', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.textTheme.bodyMedium?.fontFamily, 'Archivo');
      expect(darkTheme.textTheme.bodyMedium?.fontFamily, 'Archivo');

      expect(AppTextStyles.statusMono.fontFamily, 'Space Mono');
      expect(AppTextStyles.statusMono.fontSize, 12);
      expect(AppTextStyles.statusMono.fontWeight, FontWeight.w400);

      expect(AppTextStyles.uiBody.fontFamily, 'Archivo');
      expect(AppTextStyles.uiBody.fontSize, 16);
      expect(AppTextStyles.uiBody.fontWeight, FontWeight.w400);

      expect(AppTextStyles.epubReading.fontFamily, 'Spectral');
      expect(AppTextStyles.epubReading.fontSize, 16);

      expect(AppTextStyles.sectionTitle.fontFamily, 'Spectral');
      expect(AppTextStyles.sectionTitle.fontSize, 20);
      expect(AppTextStyles.sectionTitle.fontWeight, FontWeight.w600);

      expect(AppTextStyles.brandDisplay.fontFamily, 'Spectral');
      expect(AppTextStyles.brandDisplay.fontSize, 28);
      expect(AppTextStyles.brandDisplay.fontWeight, FontWeight.w600);
    });

    test('spacing scale matches 14-UI-SPEC contract values', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
      expect(AppSpacing.xxxl, 64.0);
    });

    test('light and dark ThemeExtensions contain required tokens', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      final lightExt = lightTheme.extension<AppThemeExtension>();
      final darkExt = darkTheme.extension<AppThemeExtension>();

      expect(lightExt, isNotNull);
      expect(darkExt, isNotNull);

      expect(lightExt!.grifo, AppColors.lightGrifo);
      expect(lightExt.moss, AppColors.lightMoss);
      expect(lightExt.card, AppColors.lightCard);
      expect(lightExt.cardElevated, AppColors.lightCardElevated);

      expect(darkExt!.grifo, AppColors.darkGrifo);
      expect(darkExt.moss, AppColors.darkMoss);
      expect(darkExt.card, AppColors.darkCard);
      expect(darkExt.cardElevated, AppColors.darkCardElevated);
    });

    test('bundled font files exist locally with license files', () {
      final requiredFiles = [
        'assets/fonts/spectral/Spectral-Regular.ttf',
        'assets/fonts/spectral/Spectral-SemiBold.ttf',
        'assets/fonts/spectral/OFL.txt',
        'assets/fonts/archivo/Archivo-Regular.ttf',
        'assets/fonts/archivo/Archivo-SemiBold.ttf',
        'assets/fonts/archivo/OFL.txt',
        'assets/fonts/space_mono/SpaceMono-Regular.ttf',
        'assets/fonts/space_mono/SpaceMono-Bold.ttf',
        'assets/fonts/space_mono/OFL.txt',
      ];

      for (final path in requiredFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Missing $path');
        expect(file.lengthSync(), greaterThan(0), reason: 'Empty file $path');
      }
    });

    test('all 4 theme palettes construct valid light and dark ThemeData with extensions', () {
      for (final palette in AppThemePalette.values) {
        final lightTheme = AppTheme.light(palette: palette);
        final darkTheme = AppTheme.dark(palette: palette);

        expect(lightTheme.brightness, Brightness.light);
        expect(darkTheme.brightness, Brightness.dark);

        final lightExt = lightTheme.extension<AppThemeExtension>();
        final darkExt = darkTheme.extension<AppThemeExtension>();

        expect(lightExt, isNotNull, reason: 'Light ThemeExtension missing for ${palette.label}');
        expect(darkExt, isNotNull, reason: 'Dark ThemeExtension missing for ${palette.label}');

        final lightTokens = AppColors.getLightTokens(palette);
        final darkTokens = AppColors.getDarkTokens(palette);

        expect(lightExt!.grifo, lightTokens.grifo);
        expect(lightExt.moss, lightTokens.moss);
        expect(lightExt.card, lightTokens.card);
        expect(lightExt.cardElevated, lightTokens.cardElevated);

        expect(darkExt!.grifo, darkTokens.grifo);
        expect(darkExt.moss, darkTokens.moss);
        expect(darkExt.card, darkTokens.card);
        expect(darkExt.cardElevated, darkTokens.cardElevated);
      }
    });

    test('production code contains zero web/html/webview references', () {
      final libDir = Directory('lib');
      final files = libDir.listSync(recursive: true).whereType<File>();

      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        expect(content.contains('WebView'), isFalse, reason: '${file.path} contains WebView');
        expect(content.contains('HtmlElementView'), isFalse, reason: '${file.path} contains HtmlElementView');
        expect(content.contains('vozlume_redesign.html'), isFalse, reason: '${file.path} references html at runtime');
      }
    });
  });

  group('ThemePreferenceRepository', () {
    late Directory tempDir;
    late File tempFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('theme_pref_test_');
      tempFile = File('${tempDir.path}/test_theme_pref.json');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('defaults to ThemeMode.system and AppThemePalette.padrao when file does not exist', () async {
      final repo = ThemePreferenceRepository(overrideFile: tempFile);
      final state = await repo.loadState();
      expect(state.mode, ThemeMode.system);
      expect(state.palette, AppThemePalette.padrao);
    });

    test('saves and reloads ThemeMode and AppThemePalette correctly', () async {
      final repo = ThemePreferenceRepository(overrideFile: tempFile);

      await repo.saveState(const ThemePreferenceState(
        mode: ThemeMode.dark,
        palette: AppThemePalette.botanico,
      ));
      var loaded = await repo.loadState();
      expect(loaded.mode, ThemeMode.dark);
      expect(loaded.palette, AppThemePalette.botanico);

      await repo.saveState(const ThemePreferenceState(
        mode: ThemeMode.light,
        palette: AppThemePalette.marinha,
      ));
      loaded = await repo.loadState();
      expect(loaded.mode, ThemeMode.light);
      expect(loaded.palette, AppThemePalette.marinha);

      await repo.saveState(const ThemePreferenceState(
        mode: ThemeMode.system,
        palette: AppThemePalette.arquivo,
      ));
      loaded = await repo.loadState();
      expect(loaded.mode, ThemeMode.system);
      expect(loaded.palette, AppThemePalette.arquivo);
    });

    test('recovers gracefully to defaults on corrupted file', () async {
      tempFile.writeAsStringSync('{ corrupted json: true ///');
      final repo = ThemePreferenceRepository(overrideFile: tempFile);
      final state = await repo.loadState();
      expect(state.mode, ThemeMode.system);
      expect(state.palette, AppThemePalette.padrao);
    });
  });
}
