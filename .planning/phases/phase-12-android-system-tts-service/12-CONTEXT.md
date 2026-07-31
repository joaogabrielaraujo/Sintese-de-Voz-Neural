# CONTEXT: Fase 12 - Plugin Nativo Android System-Wide TTS Service

## 🎯 Objetivo
Expor a engine neural local do aplicativo como um motor TTS oficial do sistema operacional Android (`TextToSpeechService`), de forma idêntica à arquitetura do **VoxSherpa-TTS** (`VoxSherpaTtsService.java`). Isso permite que o usuário selecione a voz do aplicativo nas configurações de acessibilidade do celular e a utilize em outros aplicativos do dispositivo (como Chrome, leitores de PDF e TalkBack).

---

## 🛠️ Decisões Arquiteturais Locked

### 1. Serviço Nativo Android (`android.speech.tts.TextToSpeechService`)
- **`VoxSystemTtsService.kt`**: Classe estendendo `TextToSpeechService` no diretório nativo Android (`android/app/src/main/kotlin/`).
- **Callback de Síntese (`SynthesisCallback`)**:
  - `callback.start(sampleRate, AudioFormat.ENCODING_PCM_16BIT, 1)`
  - `callback.audioAvailable(buffer, offset, length)`
  - `callback.done()`

### 2. Registro no Android Manifest (`AndroidManifest.xml`)
- Declaração do serviço de acessibilidade TTS com `<intent-filter>`:
  `<action android:name="android.intent.action.TTS_SERVICE" />`
  `<category android:name="android.intent.category.DEFAULT" />`

### 3. Ponte de Comunicação Flutter-Nativo (`AndroidSystemTtsBridge`)
- `MethodChannel('com.example.tcc_tts_neural/system_tts')` em `lib/core/system/android_system_tts_bridge.dart` para sincronização de configurações de voz, modelo ativo e amostragem.

---

## 📋 Critérios de Aceitação
- [ ] Classe `VoxSystemTtsService.kt` criada e registrada no Android Manifest.
- [ ] Classe `AndroidSystemTtsBridge` criada em Flutter (`lib/core/system/`).
- [ ] Testes unitários para a ponte de comunicação do canal nativo.
- [ ] 100% dos testes do projeto aprovados.
