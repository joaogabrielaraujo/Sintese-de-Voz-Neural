/// Modelo de dados contendo estatísticas em tempo real do uso de memória RAM por buffers de áudio.
class MemoryStats {
  /// Total de bytes atualmente alocados em RAM para buffers PCM ativos.
  final int allocatedBytes;

  /// Quantidade total de itens de áudio que já sofreram descarte/purge.
  final int purgedItemsCount;

  /// Quantidade acumulada de bytes liberados da memória.
  final int freedBytes;

  const MemoryStats({
    required this.allocatedBytes,
    required this.purgedItemsCount,
    required this.freedBytes,
  });

  /// Pegada de memória atualmente alocada em Megabytes (MB).
  double get allocatedMb => allocatedBytes / (1024.0 * 1024.0);

  /// Pegada total de memória liberada em Megabytes (MB).
  double get freedMb => freedBytes / (1024.0 * 1024.0);

  @override
  String toString() =>
      'MemoryStats(alocado: ${allocatedMb.toStringAsFixed(2)}MB, purged: $purgedItemsCount items, liberado: ${freedMb.toStringAsFixed(2)}MB)';
}
