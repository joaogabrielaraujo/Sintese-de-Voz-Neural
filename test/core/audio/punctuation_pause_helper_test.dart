import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/punctuation_pause_helper.dart';

void main() {
  group('PunctuationPauseHelper - Testes Unitários de Ritmo e Silêncios PCM', () {
    test('Deve mapear durações base de pontuação corretamente', () {
      expect(PunctuationPauseHelper.getBasePauseMs(','), equals(140));
      expect(PunctuationPauseHelper.getBasePauseMs('!'), equals(190));
      expect(PunctuationPauseHelper.getBasePauseMs('?'), equals(230));
      expect(PunctuationPauseHelper.getBasePauseMs('.'), equals(280));
      expect(PunctuationPauseHelper.getBasePauseMs('...'), equals(380));
      expect(PunctuationPauseHelper.getBasePauseMs('texto comum'), equals(0));
    });

    test('Deve calcular a duração de silêncio com escalonamento por velocidade', () {
      final int pauseNormal = PunctuationPauseHelper.calculatePauseDurationMs(
        baseMs: 280,
        speed: 1.0,
        applyJitter: false,
      );
      expect(pauseNormal, equals(280));

      final int pauseFast = PunctuationPauseHelper.calculatePauseDurationMs(
        baseMs: 280,
        speed: 2.0,
        applyJitter: false,
      );
      expect(pauseFast, equals(140)); // 280 / 2.0 = 140

      final int pauseSlow = PunctuationPauseHelper.calculatePauseDurationMs(
        baseMs: 280,
        speed: 0.5,
        applyJitter: false,
      );
      expect(pauseSlow, equals(560)); // 280 / 0.5 = 560
    });

    test('Deve aplicar multiplicador de intensidade de pausa configurado pelo usuário', () {
      final int durationHigh = PunctuationPauseHelper.calculatePauseDurationMs(
        baseMs: 200,
        intensity: 1.5,
        applyJitter: false,
      );
      expect(durationHigh, equals(300)); // 200 * 1.5 = 300
    });

    test('Deve gerar buffer de bytes PCM 16-bit com tamanho exato para 16kHz, 22.05kHz e 24kHz', () {
      // 100ms em 22.05kHz Mono Int16:
      // (22050 * 100) / 1000 = 2205 amostras * 2 bytes = 4410 bytes
      final buffer22k = PunctuationPauseHelper.generateSilenceBuffer(
        durationMs: 100,
        sampleRate: 22050,
      );
      expect(buffer22k.length, equals(4410));
      expect(buffer22k.every((byte) => byte == 0), isTrue);

      // 100ms em 24kHz Mono Int16:
      // (24000 * 100) / 1000 = 2400 amostras * 2 bytes = 4800 bytes
      final buffer24k = PunctuationPauseHelper.generateSilenceBuffer(
        durationMs: 100,
        sampleRate: 24000,
      );
      expect(buffer24k.length, equals(4800));

      // 100ms em 16kHz Mono Int16:
      // (16000 * 100) / 1000 = 1600 amostras * 2 bytes = 3200 bytes
      final buffer16k = PunctuationPauseHelper.generateSilenceBuffer(
        durationMs: 100,
        sampleRate: 16000,
      );
      expect(buffer16k.length, equals(3200));
    });

    test('Deve calcular o total de silêncio estimado em um texto com múltiplas pontuações', () {
      const String text = 'Olá, este é um teste! Tudo bem? Sim... Funciona.';
      // Pausas: , (140) + ! (190) + ? (230) + ... (380) + . (280) = 1220 ms
      final int totalMs = PunctuationPauseHelper.calculateTotalSilenceInText(text);
      expect(totalMs, equals(1220));
    });
  });
}
