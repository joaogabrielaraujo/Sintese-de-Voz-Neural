package com.example.tcc_tts_neural

import android.speech.tts.SynthesisCallback
import android.speech.tts.SynthesisRequest
import android.speech.tts.TextToSpeech
import android.speech.tts.TextToSpeechService
import android.media.AudioFormat
import java.util.Locale

/**
 * Serviço Nativo Android para disponibilizar o modelo VITS ONNX local
 * como um motor TTS padrão do sistema operacional Android.
 *
 * Inspirado na arquitetura do VoxSherpa-TTS (`VoxSherpaTtsService.java`).
 */
class VoxSystemTtsService : TextToSpeechService() {

    @Volatile
    private var isCancelled = false

    override fun onCreate() {
        super.onCreate()
    }

    override fun onGetLanguage(): Array<String> {
        return arrayOf("por", "BRA", "")
    }

    override fun onIsLanguageAvailable(lang: String?, country: String?, variant: String?): Int {
        if (lang != null && (lang.equals("por", ignoreCase = true) || lang.equals("pt", ignoreCase = true))) {
            return TextToSpeech.LANG_AVAILABLE
        }
        return TextToSpeech.LANG_NOT_SUPPORTED
    }

    override fun onLoadLanguage(lang: String?, country: String?, variant: String?): Int {
        return onIsLanguageAvailable(lang, country, variant)
    }

    override fun onStop() {
        isCancelled = true
    }

    override fun onSynthesizeText(request: SynthesisRequest?, callback: SynthesisCallback?) {
        if (request == null || callback == null) return

        val text = request.charSequenceText?.toString() ?: ""
        if (text.isEmpty()) return

        isCancelled = false

        val sampleRate = 22050
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val channelCount = 1

        callback.start(sampleRate, audioFormat, channelCount)

        // Gerar buffer de silêncio/PCM de demonstração zerado
        val bufferSize = 2205 * 2 // 100ms em 22.05kHz
        val pcmBuffer = ByteArray(bufferSize)

        var written = 0
        while (written < bufferSize && !isCancelled) {
            val chunkSize = Math.min(1024, bufferSize - written)
            callback.audioAvailable(pcmBuffer, written, chunkSize)
            written += chunkSize
        }

        callback.done()
    }
}
