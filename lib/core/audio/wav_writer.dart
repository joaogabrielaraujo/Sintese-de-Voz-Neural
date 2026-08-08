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

  /// Trim trailing near-silent samples, leaving a natural human breath pause of [padMs] (default 250ms).
  AudioBuffer trimSilence({double threshold = 0.005, int padMs = 250}) {
    if (samples.isEmpty) return this;
    int lastIndex = samples.length - 1;
    while (lastIndex >= 0 && samples[lastIndex].abs() < threshold) {
      lastIndex--;
    }
    if (lastIndex < 0) return this;
    final nonSilentCount = lastIndex + 1;
    final padSamples = (sampleRate * (padMs / 1000.0) * numChannels).round();
    final targetCount = (nonSilentCount + padSamples).clamp(0, samples.length);
    if (targetCount == samples.length) return this;
    return AudioBuffer(
      samples: Float32List.sublistView(samples, 0, targetCount),
      sampleRate: sampleRate,
      numChannels: numChannels,
    );
  }
}

/// Utilitário puramente funcional para serialização de áudio PCM no formato WAV (RIFF).
///
/// Desenvolvido para alta performance em Edge Computing (sem alocações desnecessárias).
class WavWriter {
  /// Converte um [AudioBuffer] de amostras Float32 para um array de bytes no padrão RIFF/WAV Int16.
  static Uint8List encodeToWav(AudioBuffer audio) {
    if (audio.sampleRate <= 0 || audio.numChannels <= 0) {
      throw ArgumentError('sampleRate and numChannels must be positive.');
    }
    if (audio.samples.length % audio.numChannels != 0) {
      throw ArgumentError(
        'Interleaved sample count must contain complete channel frames.',
      );
    }
    final int numSamples = audio.samples.length;
    const int bitsPerSample = 16;
    const int bytesPerSample = bitsPerSample ~/ 8;
    final int subChunk2Size = numSamples * bytesPerSample;
    final int chunkSize = 36 + subChunk2Size;

    final ByteData byteData = ByteData(44 + subChunk2Size);

    // 1. RIFF Header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, chunkSize, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // 2. "fmt " Sub-chunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 para PCM)
    byteData.setUint16(
      20,
      1,
      Endian.little,
    ); // AudioFormat (1 para PCM uncompressed)
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
      final int intSample =
          (sample < 0) ? (sample * 32768).round() : (sample * 32767).round();
      byteData.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// Decodifica um array de bytes no formato RIFF/WAV Int16 para um [AudioBuffer] com amostras Float32.
  static AudioBuffer decodeWav(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const FormatException('WAV is shorter than the RIFF header.');
    }
    final ByteData data = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    if (_readFourCc(bytes, 0) != 'RIFF' || _readFourCc(bytes, 8) != 'WAVE') {
      throw const FormatException('Expected RIFF/WAVE signature.');
    }

    final int riffEnd = data.getUint32(4, Endian.little) + 8;
    if (riffEnd > bytes.length || riffEnd < 12) {
      throw const FormatException('RIFF chunk declares an invalid size.');
    }

    int? audioFormat;
    int? sampleRate;
    int? numChannels;
    int? bitsPerSample;
    int? blockAlign;
    int? byteRate;
    int? dataOffset;
    int? dataSize;

    int offset = 12;
    while (offset + 8 <= riffEnd) {
      final String chunkId = _readFourCc(bytes, offset);
      final int chunkSize = data.getUint32(offset + 4, Endian.little);
      final int payloadOffset = offset + 8;
      final int payloadEnd = payloadOffset + chunkSize;
      if (payloadEnd > riffEnd) {
        throw FormatException('$chunkId chunk exceeds the RIFF boundary.');
      }

      if (chunkId == 'fmt ') {
        if (chunkSize < 16) {
          throw const FormatException('fmt chunk is too short.');
        }
        audioFormat = data.getUint16(payloadOffset, Endian.little);
        numChannels = data.getUint16(payloadOffset + 2, Endian.little);
        sampleRate = data.getUint32(payloadOffset + 4, Endian.little);
        byteRate = data.getUint32(payloadOffset + 8, Endian.little);
        blockAlign = data.getUint16(payloadOffset + 12, Endian.little);
        bitsPerSample = data.getUint16(payloadOffset + 14, Endian.little);
      } else if (chunkId == 'data' && dataOffset == null) {
        dataOffset = payloadOffset;
        dataSize = chunkSize;
      }

      offset = payloadEnd + (chunkSize.isOdd ? 1 : 0);
      if (offset > riffEnd) {
        throw FormatException('$chunkId chunk is missing its padding byte.');
      }
    }

    if (audioFormat == null || dataOffset == null || dataSize == null) {
      throw const FormatException('WAV requires both fmt and data chunks.');
    }
    if (audioFormat != 1 || bitsPerSample != 16) {
      throw FormatException(
        'Unsupported WAV format: format=$audioFormat, bits=$bitsPerSample. Only PCM16 is supported.',
      );
    }
    if (sampleRate == null ||
        sampleRate <= 0 ||
        numChannels == null ||
        numChannels <= 0) {
      throw const FormatException(
        'WAV contains an invalid sample rate or channel count.',
      );
    }

    final int expectedBlockAlign = numChannels * 2;
    if (blockAlign != expectedBlockAlign ||
        byteRate != sampleRate * expectedBlockAlign ||
        dataSize % expectedBlockAlign != 0) {
      throw const FormatException('WAV PCM format fields are inconsistent.');
    }

    final int totalSamples = dataSize ~/ 2;
    final Float32List floatSamples = Float32List(totalSamples);

    int sampleIdx = 0;
    final int dataEnd = dataOffset + dataSize;
    for (int i = dataOffset; i < dataEnd; i += 2) {
      final int intSample = data.getInt16(i, Endian.little);
      floatSamples[sampleIdx++] =
          (intSample < 0) ? intSample / 32768.0 : intSample / 32767.0;
    }

    return AudioBuffer(
      samples: floatSamples,
      sampleRate: sampleRate,
      numChannels: numChannels,
    );
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

  static String _readFourCc(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }
}
