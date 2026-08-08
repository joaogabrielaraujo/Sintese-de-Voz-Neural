import 'dart:io';

/// Local installation details for a Supertonic 3 model.
class SupertonicConfig {
  static const requiredFiles = <String>[
    'duration_predictor.int8.onnx',
    'text_encoder.int8.onnx',
    'vector_estimator.int8.onnx',
    'vocoder.int8.onnx',
    'tts.json',
    'unicode_indexer.bin',
    'voice.bin',
  ];

  final String modelDirectory;
  final String? nativeLibraryDirectory;
  final String language;
  final int speakerId;
  final double speed;
  final int numSteps;
  final int numThreads;

  const SupertonicConfig({
    required this.modelDirectory,
    this.nativeLibraryDirectory,
    this.language = 'pt',
    this.speakerId = 0,
    this.speed = 1,
    this.numSteps = 8,
    this.numThreads = 2,
  });

  String pathFor(String fileName) =>
      '$modelDirectory${Platform.pathSeparator}$fileName';

  List<String> get missingFiles => requiredFiles.where((name) {
        final file = File(pathFor(name));
        return !file.existsSync() || file.lengthSync() == 0;
      }).toList(growable: false);

  bool get isInstalled => missingFiles.isEmpty;
}
