import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../engine/tts_engine_type.dart';

class TTSEnginePreferenceRepository {
  final File? _overrideFile;

  TTSEnginePreferenceRepository({File? overrideFile})
      : _overrideFile = overrideFile;

  Future<File> _file() async {
    final overrideFile = _overrideFile;
    if (overrideFile != null) return overrideFile;
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/tts_engine_preference.json');
  }

  Future<TTSEngineType> load({required bool hasSupertonic}) async {
    try {
      final file = await _file();
      if (!await file.exists()) return TTSEngineType.autoFailover;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final saved = TTSEngineType.values.where(
        (type) => type.name == data['engineType'],
      );
      if (saved.isEmpty) return TTSEngineType.autoFailover;
      final type = saved.first;
      if (type == TTSEngineType.supertonic && !hasSupertonic) {
        return TTSEngineType.autoFailover;
      }
      return type;
    } on Object {
      return TTSEngineType.autoFailover;
    }
  }

  Future<void> save(TTSEngineType type) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'engineType': type.name}));
    } on Object {
      // A preferência não pode impedir o funcionamento do leitor.
    }
  }
}
