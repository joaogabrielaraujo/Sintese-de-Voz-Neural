import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_tts_neural/core/audio/wav_writer.dart';

void main() {
  test('encodes interleaved mono and stereo sizes correctly', () {
    final mono = WavWriter.encodeToWav(
      AudioBuffer(
        samples: Float32List.fromList([0.1, -0.1]),
        sampleRate: 22050,
      ),
    );
    final stereo = WavWriter.encodeToWav(
      AudioBuffer(
        samples: Float32List.fromList([0.1, -0.1, 0.2, -0.2]),
        sampleRate: 22050,
        numChannels: 2,
      ),
    );

    expect(ByteData.sublistView(mono).getUint32(40, Endian.little), 4);
    expect(ByteData.sublistView(stereo).getUint32(40, Endian.little), 8);
    expect(WavWriter.decodeWav(stereo).durationInSeconds, 2 / 22050);
  });

  test('rejects malformed and unsupported WAV input', () {
    expect(() => WavWriter.decodeWav(Uint8List(8)), throwsFormatException);

    final pcm16 = WavWriter.encodeToWav(
      AudioBuffer(
        samples: Float32List.fromList([0.1, -0.1]),
        sampleRate: 22050,
      ),
    );
    final truncated = Uint8List.sublistView(pcm16, 0, pcm16.length - 1);
    expect(() => WavWriter.decodeWav(truncated), throwsFormatException);

    final pcm24 = Uint8List.fromList(pcm16);
    ByteData.sublistView(pcm24).setUint16(34, 24, Endian.little);
    expect(() => WavWriter.decodeWav(pcm24), throwsFormatException);

    final floatWav = Uint8List.fromList(pcm16);
    ByteData.sublistView(floatWav).setUint16(20, 3, Endian.little);
    expect(() => WavWriter.decodeWav(floatWav), throwsFormatException);
  });

  test('parses odd-sized chunks and ignores bytes after declared data', () {
    final bytes = Uint8List(58);
    final data = ByteData.sublistView(bytes);
    _write(bytes, 0, 'RIFF');
    data.setUint32(4, 50, Endian.little);
    _write(bytes, 8, 'WAVE');
    _write(bytes, 12, 'JUNK');
    data.setUint32(16, 1, Endian.little);
    bytes[20] = 7;
    bytes[21] = 0;
    _write(bytes, 22, 'fmt ');
    data.setUint32(26, 16, Endian.little);
    data.setUint16(30, 1, Endian.little);
    data.setUint16(32, 1, Endian.little);
    data.setUint32(34, 22050, Endian.little);
    data.setUint32(38, 44100, Endian.little);
    data.setUint16(42, 2, Endian.little);
    data.setUint16(44, 16, Endian.little);
    _write(bytes, 46, 'data');
    data.setUint32(50, 2, Endian.little);
    data.setInt16(54, 16384, Endian.little);
    bytes[56] = 99;
    bytes[57] = 100;

    final decoded = WavWriter.decodeWav(bytes);
    expect(decoded.samples, hasLength(1));
    expect(decoded.samples.single, closeTo(0.5, 0.001));
  });
}

void _write(Uint8List bytes, int offset, String value) {
  for (var i = 0; i < value.length; i++) {
    bytes[offset + i] = value.codeUnitAt(i);
  }
}
