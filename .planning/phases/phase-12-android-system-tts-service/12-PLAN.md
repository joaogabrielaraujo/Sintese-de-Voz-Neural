# PLAN: Fase 12 - Plugin Nativo Android System-Wide TTS Service

## 🎯 Visão Geral da Fase
Implementar a integração com o serviço nativo `TextToSpeechService` do Android, registrando a aplicação no `AndroidManifest.xml` e criando a ponte de MethodChannel em Flutter (`AndroidSystemTtsBridge`), permitindo que a engine neural do aplicativo possa ser selecionada como sistema de síntese de voz padrão no Android.

---

## 📦 Tarefas de Implementação

### Tarefa 1: Criar Serviço Nativo Android `VoxSystemTtsService.kt`
- **Arquivo**: `android/app/src/main/kotlin/com/example/tcc_tts_neural/VoxSystemTtsService.kt`
- **Responsabilidade**:
  - Estender `android.speech.tts.TextToSpeechService`.
  - Implementar métodos `onGetLanguage`, `onIsLanguageAvailable`, `onLoadLanguage`, `onStop` e `onSynthesizeText`.
  - Transmitir buffers PCM 16-bit para o `SynthesisCallback` do Android.

### Tarefa 2: Registrar Serviço no `AndroidManifest.xml`
- **Arquivo**: `android/app/src/main/AndroidManifest.xml`
- **Responsabilidade**:
  - Adicionar o bloco `<service>` com o filtro de intenção `android.intent.action.TTS_SERVICE`.

### Tarefa 3: Criar Ponte de MethodChannel em Flutter (`AndroidSystemTtsBridge`)
- **Arquivo**: `lib/core/system/android_system_tts_bridge.dart`
- **Responsabilidade**:
  - `MethodChannel` para sincronizar modelo ativo, idioma (pt-BR), taxa de amostragem (22.05kHz/24kHz) e status do serviço entre o aplicativo e o sistema operacional.

### Tarefa 4: Escrever Testes Unitários
- **Arquivo**: `test/core/system/android_system_tts_bridge_test.dart`
- **Responsabilidade**:
  - Testar envio de comandos e tratamento de fallbacks do canal nativo.

---

## 🧪 Verificação & Critérios de Conclusão
- Executar `flutter test` e verificar 100% de aprovação.
- Executar `flutter analyze` sem erros.
