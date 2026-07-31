/// Enums de classificação do tipo de modelo ONNX.
enum OnnxModelType {
  /// Modelo MMS (Meta Multilingual Speech) baseado em caracteres (linhas < 200 em tokens.txt).
  mmsCharacter,

  /// Modelo Piper/VITS baseado em fonemas (linhas >= 200 em tokens.txt, requer espeak-ng-data).
  piperPhoneme,

  /// Modelo Kokoro 82M com suporte multidirecional.
  kokoroMultilingual,
}

/// Detector e Inspecionador de Configurações de Modelos ONNX.
///
/// Inspirado na lógica de inspeção automática do VoxSherpa-TTS (`VoiceEngine.java`).
/// Analisa o arquivo `tokens.txt` e o nome/caminho do modelo para determinar
/// automaticamente a necessidade de `espeak-ng-data` e a taxa de amostragem (Hz).
class OnnxModelDetector {
  /// Classifica se um arquivo `tokens.txt` pertence a um modelo MMS (caracteres) ou Piper (fonemas).
  ///
  /// Modelos MMS utilizam tokenização baseada em caracteres e possuem menos de 200 linhas.
  /// Modelos Piper/VITS utilizam tabela de fonemas e possuem 200+ linhas.
  static OnnxModelType detectFromTokensContent(
    String tokensContent, {
    required String modelType,
    String comment = '',
    required bool hasEspeak,
  }) {
    if (tokensContent.trim().isEmpty) {
      throw const FormatException('tokens.txt is empty.');
    }

    final normalizedType = modelType.trim().toLowerCase();
    final normalizedComment = comment.trim().toLowerCase();
    if (normalizedType.contains('kokoro')) {
      return OnnxModelType.kokoroMultilingual;
    }
    if (hasEspeak || normalizedComment.contains('piper')) {
      return OnnxModelType.piperPhoneme;
    }
    if (normalizedType.contains('mms')) {
      return OnnxModelType.mmsCharacter;
    }

    throw FormatException(
      'Unsupported or ambiguous ONNX metadata: model_type=$modelType, comment=$comment, has_espeak=$hasEspeak',
    );
  }

  /// Retorna `true` se o modelo exigir a pasta de fonemas `espeak-ng-data`.
  static bool requiresEspeakData(OnnxModelType type) {
    switch (type) {
      case OnnxModelType.mmsCharacter:
        return false;
      case OnnxModelType.piperPhoneme:
      case OnnxModelType.kokoroMultilingual:
        return true;
    }
  }

  /// Inspeciona o caminho do modelo para detectar a taxa de amostragem recomendada (Hz).
  ///
  /// Padrão: 22050 Hz para Piper VITS PT-BR (Faber), 24000 Hz para Kokoro, 16000 Hz para MMS.
  static int detectSampleRate(String modelPath, {OnnxModelType? type}) {
    final String lower = modelPath.toLowerCase();

    if (lower.contains('kokoro')) return 24000;
    if (lower.contains('16k') || lower.contains('mms')) return 16000;
    if (lower.contains('24k')) return 24000;

    if (type == OnnxModelType.mmsCharacter) return 16000;
    if (type == OnnxModelType.kokoroMultilingual) return 24000;

    return 22050; // Padrão VITS Piper Faber PT-BR
  }
}
