import 'dart:async';
import 'dart:math' as math;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import '../audio/wav_writer.dart';
import '../config/tts_config.dart';
import 'tts_engine_interface.dart';

/// Engine de Síntese que utiliza a Web Speech API do Navegador em Fila (Queue)
/// permitindo a leitura contínua de TODAS as sentenças do capítulo em voz humana nativa PT-BR.
class WebSpeechEngine extends ITTSEngine {
  @override
  final TTSConfig config;

  bool _initialized = false;

  WebSpeechEngine({TTSConfig? config})
      : config = config ?? TTSConfig.defaultPtBr();

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  /// Cancela qualquer áudio em reprodução anterior
  void cancelSpeech() {
    if (html.window.speechSynthesis != null) {
      html.window.speechSynthesis!.cancel();
    }
  }

  /// Adiciona uma sentença à fila de reprodução sequencial do navegador
  void queueSentence(String text, {double rate = 1.0}) {
    if (html.window.speechSynthesis != null && text.trim().isNotEmpty) {
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'pt-BR';
      utterance.rate = rate.clamp(0.5, 2.0);
      utterance.pitch = 1.0;
      // Enfileira a sentença no sintetizador nativo sem cancelar a frase anterior
      html.window.speechSynthesis!.speak(utterance);
    }
  }

  /// Pausa a reprodução da fila
  void pauseSpeech() {
    if (html.window.speechSynthesis != null) {
      html.window.speechSynthesis!.pause();
    }
  }

  /// Retoma a reprodução da fila
  void resumeSpeech() {
    if (html.window.speechSynthesis != null) {
      html.window.speechSynthesis!.resume();
    }
  }

  @override
  Future<AudioBuffer> synthesize(String text) async {
    // Adiciona a sentença sequencialmente na fila do sintetizador do browser
    queueSentence(text);

    final double durationSeconds = math.max(0.8, text.length / 14.0);
    final int numSamples = (durationSeconds * config.sampleRate).round();

    return AudioBuffer(
      samples: Float32List(numSamples),
      sampleRate: config.sampleRate,
    );
  }

  @override
  Future<void> dispose() async {
    cancelSpeech();
    _initialized = false;
  }
}
