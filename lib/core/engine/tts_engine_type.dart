/// Tipos de Motores de Inferência TTS disponíveis no ecossistema do TCC.
enum TTSEngineType {
  /// Modo Resiliente Inteligente com Failover Automático (Sherpa ONNX -> VITS Local -> Native TTS)
  autoFailover,

  /// Motor Neural C++ Sherpa-ONNX VITS (Modelo pt_BR-faber-medium.onnx)
  sherpaOnnx,

  /// Motor Neural Sherpa-ONNX via Processo Isolado CLI (Imune a Segfaults no Windows)
  sherpaOnnxCli,

  /// Motor Neural VITS ONNX Local em Dart (100% Seguro em Memória)
  vitsLocal,

  /// Voz Nativa do Sistema Operacional (Windows SAPI5 / Android TTS / iOS AVTTS)
  flutterTts,
}

extension TTSEngineTypeExtension on TTSEngineType {
  String get label {
    switch (this) {
      case TTSEngineType.autoFailover:
        return '🤖 Auto-Failover (Inteligente)';
      case TTSEngineType.sherpaOnnx:
        return '⚡ Sherpa-ONNX C++ (HiFi-GAN Faber)';
      case TTSEngineType.sherpaOnnxCli:
        return '🛡️ Sherpa-ONNX CLI (Processo Isolado Windows)';
      case TTSEngineType.vitsLocal:
        return '🛡️ VITS Local (100% Seguro em Memória)';
      case TTSEngineType.flutterTts:
        return '🗣️ Voz Nativa (Windows SAPI5 / Sistema)';
    }
  }

  String get description {
    switch (this) {
      case TTSEngineType.autoFailover:
        return 'Tenta Sherpa-ONNX CLI/C++. Se falhar no Windows/Android, chaveia automaticamente para VITS Local/Nativo.';
      case TTSEngineType.sherpaOnnx:
        return 'Inferência C++ HiFi-GAN em tempo real do modelo Faber em Português BR.';
      case TTSEngineType.sherpaOnnxCli:
        return 'Inferência isolada por processo CLI de linha de comando imune a falhas em memória.';
      case TTSEngineType.vitsLocal:
        return 'Motor de inferência neural local em memória Dart imune a crashes FFI.';
      case TTSEngineType.flutterTts:
        return 'Sintetizador nativo do sistema operacional (SAPI5 / Android / iOS).';
    }
  }
}
