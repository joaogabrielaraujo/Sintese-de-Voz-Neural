import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ThemePreferenceRepository {
  final File? _overrideFile;

  ThemePreferenceRepository({File? overrideFile}) : _overrideFile = overrideFile;

  Future<File> _getFile() async {
    if (_overrideFile != null) return _overrideFile!;
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/theme_preference.json');
  }

  Future<ThemeMode> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return ThemeMode.system;
      final content = await file.readAsString();
      final data = jsonDecode(content);
      final modeStr = data['themeMode'] as String?;
      switch (modeStr) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    try {
      final file = await _getFile();
      await file.parent.create(recursive: true);
      String modeStr;
      switch (mode) {
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
      await file.writeAsString(jsonEncode({'themeMode': modeStr}));
    } catch (_) {
      // Retain resiliency, do not throw
    }
  }
}
