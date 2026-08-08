import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app_theme.dart';

/// Estado persistido das preferências de tema do usuário (Modo claro/escuro/sistema + Paleta).
class ThemePreferenceState {
  final ThemeMode mode;
  final AppThemePalette palette;

  const ThemePreferenceState({
    this.mode = ThemeMode.system,
    this.palette = AppThemePalette.padrao,
  });
}

class ThemePreferenceRepository {
  final File? _overrideFile;

  ThemePreferenceRepository({File? overrideFile}) : _overrideFile = overrideFile;

  Future<File> _getFile() async {
    if (_overrideFile != null) return _overrideFile!;
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/theme_preference.json');
  }

  Future<ThemePreferenceState> loadState() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return const ThemePreferenceState();
      final content = await file.readAsString();
      final data = jsonDecode(content);

      final modeStr = data['themeMode'] as String?;
      ThemeMode mode;
      switch (modeStr) {
        case 'light':
          mode = ThemeMode.light;
          break;
        case 'dark':
          mode = ThemeMode.dark;
          break;
        case 'system':
        default:
          mode = ThemeMode.system;
          break;
      }

      final paletteStr = data['themePalette'] as String?;
      AppThemePalette palette;
      switch (paletteStr) {
        case 'botanico':
          palette = AppThemePalette.botanico;
          break;
        case 'carmim':
        case 'arquivo':
          palette = AppThemePalette.carmim;
          break;
        case 'marinha':
          palette = AppThemePalette.marinha;
          break;
        case 'padrao':
        default:
          palette = AppThemePalette.padrao;
          break;
      }

      return ThemePreferenceState(mode: mode, palette: palette);
    } catch (_) {
      return const ThemePreferenceState();
    }
  }

  Future<ThemeMode> load() async {
    final state = await loadState();
    return state.mode;
  }

  Future<void> saveState(ThemePreferenceState state) async {
    try {
      final file = await _getFile();
      await file.parent.create(recursive: true);

      String modeStr;
      switch (state.mode) {
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        case ThemeMode.system:
        default:
          modeStr = 'system';
          break;
      }

      String paletteStr;
      switch (state.palette) {
        case AppThemePalette.botanico:
          paletteStr = 'botanico';
          break;
        case AppThemePalette.arquivo:
          paletteStr = 'arquivo';
          break;
        case AppThemePalette.marinha:
          paletteStr = 'marinha';
          break;
        case AppThemePalette.padrao:
        default:
          paletteStr = 'padrao';
          break;
      }

      await file.writeAsString(jsonEncode({
        'themeMode': modeStr,
        'themePalette': paletteStr,
      }));
    } catch (_) {
      // Retain resiliency
    }
  }

  Future<void> save(ThemeMode mode, {AppThemePalette? palette}) async {
    final currentState = await loadState();
    await saveState(ThemePreferenceState(
      mode: mode,
      palette: palette ?? currentState.palette,
    ));
  }
}
