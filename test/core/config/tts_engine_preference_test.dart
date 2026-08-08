import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/tts_engine_preference.dart';
import 'package:tcc_tts_neural/core/engine/tts_engine_type.dart';

void main() {
  test('persists an available engine preference', () async {
    final directory = Directory.systemTemp.createTempSync('tts-pref-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final repository = TTSEnginePreferenceRepository(
      overrideFile: File('${directory.path}/preference.json'),
    );

    await repository.save(TTSEngineType.supertonic);

    expect(
      await repository.load(hasSupertonic: true),
      TTSEngineType.supertonic,
    );
  });

  test('returns to automatic fallback when Supertonic is unavailable',
      () async {
    final directory = Directory.systemTemp.createTempSync('tts-pref-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final repository = TTSEnginePreferenceRepository(
      overrideFile: File('${directory.path}/preference.json'),
    );
    await repository.save(TTSEngineType.supertonic);

    expect(
      await repository.load(hasSupertonic: false),
      TTSEngineType.autoFailover,
    );
  });
}
