import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ponte de Comunicação via `MethodChannel` para sincronização com o serviço nativo Android TTS (`VoxSystemTtsService`).
class AndroidSystemTtsBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.tcc_tts_neural/system_tts');

  /// Atualiza o modelo ativo e a taxa de amostragem na camada nativa do Android.
  static Future<bool> updateActiveModelConfig({
    required String modelPath,
    required String tokensPath,
    int sampleRate = 22050,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false; // Retorna silenciosamente em plataformas desktop/web
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'updateModelConfig',
        <String, dynamic>{
          'modelPath': modelPath,
          'tokensPath': tokensPath,
          'sampleRate': sampleRate,
        },
      );
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AndroidSystemTtsBridge ERROR] Falha no MethodChannel: ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o serviço nativo Android TTS está ativo no sistema operacional.
  static Future<bool> isServiceAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      final bool? available = await _channel.invokeMethod<bool>('isServiceAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }
}
