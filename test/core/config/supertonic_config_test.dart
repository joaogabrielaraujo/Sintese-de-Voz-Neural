import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/config/supertonic_config.dart';

void main() {
  test('reports every missing Supertonic model component', () {
    final directory = Directory.systemTemp.createTempSync('supertonic-empty-');
    addTearDown(() => directory.deleteSync(recursive: true));

    final config = SupertonicConfig(modelDirectory: directory.path);

    expect(config.isInstalled, isFalse);
    expect(config.missingFiles, SupertonicConfig.requiredFiles);
  });

  test('accepts a complete non-empty Supertonic installation', () {
    final directory = Directory.systemTemp.createTempSync('supertonic-full-');
    addTearDown(() => directory.deleteSync(recursive: true));
    for (final name in SupertonicConfig.requiredFiles) {
      File('${directory.path}${Platform.pathSeparator}$name')
          .writeAsStringSync('fixture');
    }

    final config = SupertonicConfig(modelDirectory: directory.path);

    expect(config.isInstalled, isTrue);
    expect(config.missingFiles, isEmpty);
  });
}
