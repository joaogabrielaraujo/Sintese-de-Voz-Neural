import 'dart:math' as math;
import 'dart:typed_data';

/// Utilitário puramente funcional para injeção de pausas e ritmos humanos de fala por pontuação.
///
/// Inspirado no algoritmo de ritmo do VoxSherpa-TTS (`AudioEmotionHelper.java`).
/// Gera buffers PCM 16-bit com valor 0 (silêncio) ajustados dinamicamente por taxa de amostragem,
/// velocidade de leitura (`speed`), intensidade configurável e variação estocástica suave (jitter).
class PunctuationPauseHelper {
  static final math.Random _random = math.Random();

  /// Durações base de pausa em milissegundos por pontuação.
  static const int pauseCommaMs = 140;
  static const int pauseExclamationMs = 190;
  static const int pauseQuestionMs = 230;
  static const int pausePeriodMs = 280;
  static const int pauseEllipsisMs = 380;

  /// Mapeia o token de pontuação para o tempo base de silêncio (ms).
  /// Retorna 0 se o token não for uma pontuação reconhecida.
  static int getBasePauseMs(String token) {
    final String trimmed = token.trim();
    if (trimmed == '...') return pauseEllipsisMs;
    if (trimmed == ',') return pauseCommaMs;
    if (trimmed == '!') return pauseExclamationMs;
    if (trimmed == '?') return pauseQuestionMs;
    if (trimmed == '.' || trimmed == '।') return pausePeriodMs;
    return 0;
  }

  /// Returns a deterministic inter-sentence pause for the final punctuation.
  static int pauseAfterTextMs(
    String text, {
    double speed = 1.0,
    double intensity = 1.0,
  }) {
    final trimmed = text.trimRight();
    if (trimmed.isEmpty) return 0;
    final token = trimmed.endsWith('...')
        ? '...'
        : trimmed.substring(trimmed.length - 1);
    return calculatePauseDurationMs(
      baseMs: getBasePauseMs(token),
      speed: speed,
      intensity: intensity,
      applyJitter: false,
    );
  }

  /// Calcula a duração final de pausa em milissegundos aplicando:
  /// 1. Escalonamento pela velocidade de reprodução (`ms / speed`).
  /// 2. Multiplicador de intensidade selecionado pelo usuário (`* intensity`).
  /// 3. Jitter estocástico suave de ±10% se [applyJitter] for true.
  static int calculatePauseDurationMs({
    required int baseMs,
    double speed = 1.0,
    double intensity = 1.0,
    bool applyJitter = true,
  }) {
    if (baseMs <= 0) return 0;

    // Escalonamento inversamente proporcional à velocidade de fala
    final double adjustedSpeed = speed > 0 ? speed : 1.0;
    double duration = (baseMs / adjustedSpeed) * intensity;

    if (applyJitter) {
      final double jitterRange = duration * 0.10; // ±10%
      final double jitter =
          (_random.nextDouble() * 2 * jitterRange) - jitterRange;
      duration += jitter;
    }

    // Trava de segurança (mínimo 60ms, máximo 1200ms)
    return duration.clamp(60.0, 1200.0).toInt();
  }

  /// Gera um array de bytes PCM Int16 mono contendo silêncio (valor 0).
  ///
  /// Exemplo para 22050 Hz, 100ms de áudio:
  /// `numSamples = (22050 * 100) / 1000 = 2205 amostras = 4410 bytes`.
  static Uint8List generateSilenceBuffer({
    required int durationMs,
    required int sampleRate,
    int channels = 1,
    int bytesPerSample = 2, // PCM 16-bit
  }) {
    if (durationMs <= 0 || sampleRate <= 0) {
      return Uint8List(0);
    }

    final int numSamples = (sampleRate * durationMs) ~/ 1000;
    final int bufferSizeBytes = numSamples * channels * bytesPerSample;

    return Uint8List(bufferSizeBytes);
  }

  /// Processa uma string e injeta buffers de silêncio PCM zerados para pontuações encontradas.
  ///
  /// Retorna o tamanho total estimado de silêncio adicionado em milissegundos.
  static int calculateTotalSilenceInText(
    String text, {
    double speed = 1.0,
    double intensity = 1.0,
  }) {
    int totalMs = 0;
    final RegExp regex = RegExp(r'(\.\.\.|[.,!?।])');
    final Iterable<RegExpMatch> matches = regex.allMatches(text);

    for (final match in matches) {
      final String token = match.group(0) ?? '';
      final int baseMs = getBasePauseMs(token);
      if (baseMs > 0) {
        totalMs += calculatePauseDurationMs(
          baseMs: baseMs,
          speed: speed,
          intensity: intensity,
          applyJitter: false,
        );
      }
    }

    return totalMs;
  }
}
