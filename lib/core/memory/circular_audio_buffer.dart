import 'dart:collection';
import 'dart:async';

import '../memory/memory_manager.dart';
import 'sentence_audio_item.dart';

/// Fila Concorrente Assíncrona (Buffer Circular FIFO) com suporte ao Padrão Produtor-Consumidor.
///
/// Possui suporte a Backpressure (controle de capacidade em memória RAM), Purge Automático de memória
/// e notificação assíncrona.
class CircularAudioBuffer {
  /// Capacidade máxima de itens na fila simultaneamente (para evitar estouro de memória RAM/OOM).
  final int maxItems;

  final Queue<SentenceAudioItem> _queue = Queue<SentenceAudioItem>();
  final StreamController<SentenceAudioItem> _streamController =
      StreamController<SentenceAudioItem>.broadcast();

  /// Gerenciador de memória com política de purge automático pós-reprodução.
  final MemoryManager memoryManager = MemoryManager();

  Completer<void>? _spaceAvailableCompleter;
  Completer<void>? _itemAvailableCompleter;

  bool _isCompleted = false;
  bool _isCancelled = false;

  CircularAudioBuffer({this.maxItems = 5});

  /// Indica se a fila atingiu a capacidade máxima.
  bool get isFull => _queue.length >= maxItems;

  /// Indica se a fila está vazia.
  bool get isEmpty => _queue.isEmpty;

  /// Quantidade atual de itens na fila.
  int get length => _queue.length;

  /// Indica se o Produtor já finalizou o enfileiramento do capítulo inteiro.
  bool get isCompleted => _isCompleted;

  /// Adiciona um item à fila (Produtor). Se a fila estiver cheia ou RAM estourar, aguarda espaço (Backpressure).
  Future<void> enqueue(SentenceAudioItem item) async {
    if (_isCancelled) {
      throw StateError('Audio buffer was cancelled.');
    }
    while (isFull || memoryManager.shouldThrottleProducer(maxMemoryMb: 50.0)) {
      _spaceAvailableCompleter ??= Completer<void>();
      await _spaceAvailableCompleter!.future;
      if (_isCancelled) {
        throw StateError('Audio buffer was cancelled.');
      }
    }

    memoryManager.trackAllocation(item);
    _queue.addLast(item);

    if (!_streamController.isClosed) {
      _streamController.add(item);
    }

    // Notifica consumidor que há item disponível
    if (_itemAvailableCompleter != null && !_itemAvailableCompleter!.isCompleted) {
      _itemAvailableCompleter!.complete();
      _itemAvailableCompleter = null;
    }
  }

  /// Remove e retorna o próximo item da fila (Consumidor) aplicando o descarte/purge da memória RAM.
  Future<SentenceAudioItem?> dequeue({bool release = true}) async {
    while (_queue.isEmpty && !_isCompleted && !_isCancelled) {
      _itemAvailableCompleter ??= Completer<void>();
      await _itemAvailableCompleter!.future;
    }

    if (_queue.isEmpty) return null;

    final item = _queue.removeFirst();

    // Aplica a política de purge pós-reprodução liberando a RAM
    if (release) {
      memoryManager.purge(item);
    }

    // Notifica produtor que há espaço disponível na fila
    if (_spaceAvailableCompleter != null && !_spaceAvailableCompleter!.isCompleted) {
      _spaceAvailableCompleter!.complete();
      _spaceAvailableCompleter = null;
    }

    return item;
  }

  /// Libera o áudio somente depois de o consumidor terminar de reproduzi-lo.
  void release(SentenceAudioItem item) {
    memoryManager.purge(item);
  }

  /// Sinaliza que o Produtor concluiu a síntese de todas as sentenças do capítulo.
  void markComplete() {
    _isCompleted = true;
    if (_itemAvailableCompleter != null && !_itemAvailableCompleter!.isCompleted) {
      _itemAvailableCompleter!.complete();
      _itemAvailableCompleter = null;
    }
  }

  /// Esvazia a fila, aplica purge em todos os itens pendentes e reseta os controles.
  void clear() {
    for (final item in _queue) {
      memoryManager.purge(item);
    }
    _queue.clear();
    _isCompleted = false;
    _isCancelled = false;
    if (_spaceAvailableCompleter != null && !_spaceAvailableCompleter!.isCompleted) {
      _spaceAvailableCompleter!.complete();
    }
    _spaceAvailableCompleter = null;

    if (_itemAvailableCompleter != null && !_itemAvailableCompleter!.isCompleted) {
      _itemAvailableCompleter!.complete();
    }
    _itemAvailableCompleter = null;
  }

  /// Stream para observação reativa dos itens enfileirados.
  Stream<SentenceAudioItem> get itemStream => _streamController.stream;

  /// Cancela produtor e consumidor, liberando itens pendentes sem deixar
  /// operações bloqueadas aguardando espaço ou novos itens.
  void cancel() {
    _isCancelled = true;
    _isCompleted = true;
    for (final item in _queue) {
      memoryManager.purge(item);
    }
    _queue.clear();
    if (_spaceAvailableCompleter != null && !_spaceAvailableCompleter!.isCompleted) {
      _spaceAvailableCompleter!.complete();
    }
    _spaceAvailableCompleter = null;
    if (_itemAvailableCompleter != null && !_itemAvailableCompleter!.isCompleted) {
      _itemAvailableCompleter!.complete();
    }
    _itemAvailableCompleter = null;
  }

  /// Libera recursos.
  void dispose() {
    cancel();
    _streamController.close();
  }
}
