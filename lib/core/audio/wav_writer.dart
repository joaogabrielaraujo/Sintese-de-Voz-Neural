import 'dart:io';
import 'dart:typed_data';

/// Modelo de dados imutável representando um buffer de áudio em memória.
class AudioBuffer {
  /// Lista de amostras em ponto flutuante normalizadas entre [-1.0, 1.0].
  final Float32List samples;

  /// Taxa de amostragem em Hertz (ex: 22050 Hz).
  final int sampleRate;

  /// Número de canais de áudio (1 = Mono, 2 = Estéreo).
  final int numChannels;

  const AudioBuffer({
    required this.samples,
    required this.sampleRate,
    this.numChannels = 1,
  });

  /// Retorna a duração exata do áudio em segundos.
  double get durationInSeconds {
    if (samples.isEmpty || sampleRate <= 0) return 0.0;
    return samples.length / (sampleRate * numChannels);
  }

  /// Retorna a duração em milissegundos.
  double get durationInMilliseconds => durationInSeconds * 1000.0;
}

/// Utilitário puramente funcional para serialização de áudio PCM no formato WAV (RIFF).
///
/// Desenvolvido para alta performance em Edge Computing (sem alocações desnecessárias).
class WavWriter {
  /// Converte um [AudioBuffer] de amostras Float32 para um array de bytes no padrão RIFF/WAV Int16.
  static Uint8List encodeToWav(AudioBuffer audio) {
    final int numSamples = audio.samples.length;
    final int bitsPerSample = 16;
    final int bytesPerSample = bitsPerSample ~/ 8;
    final int subChunk2Size = numSamples * audio.numChannels * bytesPerSample;
    final int chunkSize = 36 + subChunk2Size;

    final ByteData byteData = ByteData(44 + subChunk2Size);

    // 1. RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, chunkSize, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // 2. "fmt " Sub-chunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 para PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 para PCM uncompressed)
    byteData.setUint16(22, audio.numChannels, Endian.little);
    byteData.setUint32(24, audio.sampleRate, Endian.little);
    
    final int byteRate = audio.sampleRate * audio.numChannels * bytesPerSample;
    byteData.setUint32(28, byteRate, Endian.little);
    
    final int blockAlign = audio.numChannels * bytesPerSample;
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // 3. "data" Sub-chunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, subChunk2Size, Endian.little);

    // 4. Escrever Amostras PCM 16-bit
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      // Normalização e Clamp entre -1.0 e 1.0 para Int16 (-32768 a 32767)
      final double sample = audio.samples[i].clamp(-1.0, 1.0);
      final int intSample = (sample < 0)
          ? (sample * 32768).round()
          : (sample * 32767).round();
      byteData.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// Salva um [AudioBuffer] diretamente em um arquivo WAV no sistema de arquivos.
  static Future<File> saveToFile(AudioBuffer audio, String filePath) async {
    final Uint8List wavBytes = encodeToWav(audio);
    final File file = File(filePath);
    await file.parent.create(recursive: true);
    return await file.writeAsBytes(wavBytes, flush: true);
  }

  static void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
