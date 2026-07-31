import '../memory/sentence_audio_item.dart';
import 'memory_stats.dart';

/// Gerenciador de Memória e Política de Purge Automático de Buffers de Áudio.
///
/// Mantém o consumo de memória RAM constante ($\mathcal{O}(1)$) durante a leitura de livros inteiros.
class MemoryManager {
  int _allocatedBytes = 0;
  int _purgedItemsCount = 0;
  int _freedBytes = 0;

  /// Retorna as estatísticas atuais de memória RAM.
  MemoryStats get stats => MemoryStats(
        allocatedBytes: _allocatedBytes,
        purgedItemsCount: _purgedItemsCount,
        freedBytes: _freedBytes,
      );

  /// Registra a alocação de memória RAM para um novo item de áudio sintetizado.
  void trackAllocation(SentenceAudioItem item) {
    final int itemBytes = _calculateItemBytes(item);
    _allocatedBytes += itemBytes;
  }

  /// Executa o descarte (purge) e liberação de memória RAM de um item já reproduzido.
  void purge(SentenceAudioItem item) {
    final int itemBytes = _calculateItemBytes(item);
    if (itemBytes > 0) {
      _allocatedBytes = (_allocatedBytes - itemBytes).clamp(0, 999999999999);
      _freedBytes += itemBytes;
      _purgedItemsCount++;

      // Esvazia as amostras Float32 para liberar da memória RAM
      item.audio.samples.setAll(0, List.filled(item.audio.samples.length, 0.0));
    }
  }

  /// Indica se a síntese pelo Produtor deve ser pausada devido ao consumo de RAM atingir o teto.
  bool shouldThrottleProducer({double maxMemoryMb = 50.0}) {
    final double maxBytes = maxMemoryMb * 1024.0 * 1024.0;
    return _allocatedBytes >= maxBytes;
  }

  /// Reseta todos os contadores de memória.
  void reset() {
    _allocatedBytes = 0;
    _purgedItemsCount = 0;
    _freedBytes = 0;
  }

  int _calculateItemBytes(SentenceAudioItem item) {
    // 4 bytes por amostra em Float32
    return item.audio.samples.length * 4;
  }
}
