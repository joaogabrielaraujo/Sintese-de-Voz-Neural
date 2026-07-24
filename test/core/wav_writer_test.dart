import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';

void main() {
  group('WavWriter & AudioBuffer - Testes Unitários de Áudio', () {
    test('Deve calcular corretamente a duração do áudio em segundos', () {
      final samples = Float32List(22050 * 2); // 2 segundos a 22050Hz mono
      final buffer = AudioBuffer(samples: samples, sampleRate: 22050);

      expect(buffer.durationInSeconds, equals(2.0));
      expect(buffer.durationInMilliseconds, equals(2000.0));
    });

    test('Deve codificar corretamente o cabeçalho RIFF/WAV de 44 bytes', () {
      final samples = Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0]);
      final buffer = AudioBuffer(samples: samples, sampleRate: 22050);

      final Uint8List wavBytes = WavWriter.encodeToWav(buffer);

      // Tamanho esperado: 44 bytes de header + 5 amostras * 2 bytes = 54 bytes
      expect(wavBytes.length, equals(54));

      // Validar assinaturas do cabeçalho WAV
      final String riffHeader = String.fromCharCodes(wavBytes.sublist(0, 4));
      final String waveHeader = String.fromCharCodes(wavBytes.sublist(8, 12));
      final String fmtHeader = String.fromCharCodes(wavBytes.sublist(12, 16));
      final String dataHeader = String.fromCharCodes(wavBytes.sublist(36, 40));

      expect(riffHeader, equals('RIFF'));
      expect(waveHeader, equals('WAVE'));
      expect(fmtHeader, equals('fmt '));
      expect(dataHeader, equals('data'));
    });
  });
}
