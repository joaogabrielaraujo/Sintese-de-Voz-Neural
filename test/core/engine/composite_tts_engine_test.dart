import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';
import 'package:tcc_tts_neural/core/config/tts_config.dart';
import 'package:tcc_tts_neural/core/engine/composite_tts_engine.dart';
import 'package:tcc_tts_neural/core/engine/tts_engine_interface.dart';
import 'package:tcc_tts_neural/core/engine/tts_engine_type.dart';

class FakeAudioEngine extends ITTSEngine {
  @override
  final TTSConfig config = TTSConfig.defaultPtBr();
  final AudioBuffer output;
  final bool failInitialization;
  final bool failSynthesis;
  bool _initialized = false;

  FakeAudioEngine(
    this.output, {
    this.failInitialization = false,
    this.failSynthesis = false,
  });

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (failInitialization) {
      throw StateError('controlled initialization failure');
    }
    _initialized = true;
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    if (failSynthesis) throw StateError('controlled synthesis failure');
    return output;
  }

  @override
  Future<void> dispose() async => _initialized = false;
}

void main() {
  final audible = AudioBuffer(
    samples: Float32List.fromList([0.0, 0.2, -0.15, 0.1]),
    sampleRate: 22050,
  );
  final silent = AudioBuffer(samples: Float32List(32), sampleRate: 22050);

  test('auto failover exposes the real active engine', () async {
    final engine = CompositeTTSEngine(
      sherpaEngine: FakeAudioEngine(audible, failInitialization: true),
      cliEngine: FakeAudioEngine(audible),
    );

    await engine.initialize();
    final result = await engine.synthesize('fala real');

    expect(engine.activeType, TTSEngineType.sherpaOnnxCli);
    expect(result.samples.any((sample) => sample.abs() > 0.00001), isTrue);
    await engine.dispose();
  });

  test('auto failover prefers an installed Supertonic engine', () async {
    final engine = CompositeTTSEngine(
      supertonicEngine: FakeAudioEngine(audible),
      sherpaEngine: FakeAudioEngine(audible),
      cliEngine: FakeAudioEngine(audible),
    );

    await engine.initialize();

    expect(engine.activeType, TTSEngineType.supertonic);
    expect(engine.availableEngineTypes, contains(TTSEngineType.supertonic));
    await engine.dispose();
  });

  test('falls back from Supertonic synthesis failure to Piper', () async {
    final engine = CompositeTTSEngine(
      supertonicEngine: FakeAudioEngine(audible, failSynthesis: true),
      sherpaEngine: FakeAudioEngine(audible),
      cliEngine: FakeAudioEngine(audible),
    );

    await engine.initialize();
    final result = await engine.synthesize('fala real');

    expect(engine.activeType, TTSEngineType.sherpaOnnx);
    expect(result.samples, audible.samples);
    await engine.dispose();
  });

  test('explicit Supertonic selection fails when it is not installed',
      () async {
    final engine = CompositeTTSEngine(
      initialType: TTSEngineType.supertonic,
      sherpaEngine: FakeAudioEngine(audible),
      cliEngine: FakeAudioEngine(audible),
    );

    await expectLater(
      engine.initialize(),
      throwsA(isA<TTSEngineInitializationException>()),
    );
    expect(
        engine.availableEngineTypes, isNot(contains(TTSEngineType.supertonic)));
    await engine.dispose();
  });

  test('rejects silent primary output and switches to audible CLI', () async {
    final engine = CompositeTTSEngine(
      sherpaEngine: FakeAudioEngine(silent),
      cliEngine: FakeAudioEngine(audible),
    );

    await engine.initialize();
    final result = await engine.synthesize('fala real');

    expect(engine.activeType, TTSEngineType.sherpaOnnxCli);
    expect(result.samples, audible.samples);
    await engine.dispose();
  });

  test('never accepts fabricated silence as successful synthesis', () async {
    final engine = CompositeTTSEngine(
      sherpaEngine: FakeAudioEngine(silent),
      cliEngine: FakeAudioEngine(silent),
    );

    await engine.initialize();
    await expectLater(
      engine.synthesize('fala real'),
      throwsA(isA<TTSSynthesisException>()),
    );
    await engine.dispose();
  });

  test('unsupported pseudo-engines fail explicitly', () async {
    final engine = CompositeTTSEngine(
      initialType: TTSEngineType.vitsLocal,
      sherpaEngine: FakeAudioEngine(audible),
      cliEngine: FakeAudioEngine(audible),
    );

    await expectLater(
      engine.initialize(),
      throwsA(isA<TTSEngineInitializationException>()),
    );
    await engine.dispose();
  });
}
