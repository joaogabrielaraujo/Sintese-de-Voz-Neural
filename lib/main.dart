import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'core/audio/audio_player_service.dart';
import 'core/audio/audio_player_service_interface.dart';
import 'core/config/tts_config.dart';
import 'core/config/supertonic_config.dart';
import 'core/config/tts_engine_preference.dart';
import 'core/engine/composite_tts_engine.dart';
import 'core/engine/supertonic_onnx_engine.dart';
import 'core/engine/tts_engine_type.dart';
import 'core/document/epub_model.dart';
import 'core/document/epub_bytes_importer.dart';
import 'core/document/selected_document.dart';
import 'core/document/saved_book.dart';
import 'core/document/saved_book_repository.dart';
import 'core/memory/circular_audio_buffer.dart';
import 'core/memory/sentence_audio_item.dart';
import 'core/metrics/mos_rating_model.dart';
import 'core/pipeline/pipeline_orchestrator.dart';
import 'core/pipeline/pipeline_result.dart';
import 'core/text/sentence_segmenter.dart';
import 'core/text/sentence_model.dart';
import 'ui/widgets/mos_evaluation_dialog.dart';
import 'ui/app_theme.dart';
import 'core/config/license_registry_config.dart';
import 'ui/theme_preference.dart';
import 'ui/widgets/library_view.dart';
import 'ui/widgets/reader_page.dart';
import 'ui/widgets/responsive_navigation_shell.dart';
import 'ui/widgets/settings_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLicenseRegistry.registerLicenses();
  runApp(const TCCNeuralApp());
}

/// Aplicativo de Leitor EPUB Neural & Player de Áudio (Fase 6 - TCC UEFS).
class TCCNeuralApp extends StatefulWidget {
  final ThemePreferenceRepository? themePreferenceRepository;
  const TCCNeuralApp({super.key, this.themePreferenceRepository});

  @override
  State<TCCNeuralApp> createState() => _TCCNeuralAppState();
}

class _TCCNeuralAppState extends State<TCCNeuralApp> {
  late final ThemePreferenceRepository _themeRepo;
  ThemeMode _themeMode = ThemeMode.system;
  AppThemePalette _themePalette = AppThemePalette.padrao;

  @override
  void initState() {
    super.initState();
    _themeRepo =
        widget.themePreferenceRepository ?? ThemePreferenceRepository();
    unawaited(_loadTheme());
  }

  Future<void> _loadTheme() async {
    final state = await _themeRepo.loadState();
    if (mounted) {
      setState(() {
        _themeMode = state.mode;
        _themePalette = state.palette;
      });
    }
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
    unawaited(_themeRepo.saveState(ThemePreferenceState(mode: mode, palette: _themePalette)));
  }

  void _onThemePaletteChanged(AppThemePalette palette) {
    setState(() => _themePalette = palette);
    unawaited(_themeRepo.saveState(ThemePreferenceState(mode: _themeMode, palette: palette)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCC - Leitor EPUB Neural & Player de Áudio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(palette: _themePalette),
      darkTheme: AppTheme.dark(palette: _themePalette),
      themeMode: _themeMode,
      home: PoCNeuralHomePage(
        themeMode: _themeMode,
        onThemeModeChanged: _onThemeModeChanged,
        themePalette: _themePalette,
        onThemePaletteChanged: _onThemePaletteChanged,
      ),
    );
  }
}

class PoCNeuralHomePage extends StatefulWidget {
  final EpubDocumentPicker picker;
  final EpubBytesImporter importer;
  final PipelineOrchestrator? orchestrator;
  final IAudioPlayerService? audioPlayer;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final AppThemePalette themePalette;
  final ValueChanged<AppThemePalette>? onThemePaletteChanged;

  const PoCNeuralHomePage({
    super.key,
    this.picker = const NativeEpubDocumentPicker(),
    this.importer = const EpubBytesImporter(),
    this.orchestrator,
    this.audioPlayer,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.themePalette = AppThemePalette.padrao,
    this.onThemePaletteChanged,
  });

  @override
  State<PoCNeuralHomePage> createState() => _PoCNeuralHomePageState();
}

class _PoCNeuralHomePageState extends State<PoCNeuralHomePage>
    with WidgetsBindingObserver {
  late final CompositeTTSEngine _engine;
  late final PipelineOrchestrator _orchestrator;
  late final IAudioPlayerService _audioPlayer;
  final TTSEnginePreferenceRepository _enginePreference =
      TTSEnginePreferenceRepository();

  EpubBook? _loadedBook;
  EpubChapter? _currentChapter;

  bool _isProcessing = false;
  PipelineResult? _lastResult;
  String? _errorMessage;
  String _importStatus = 'Nenhum EPUB carregado';
  CircularAudioBuffer? _streamQueue;
  StreamIterator<SentenceAudioItem>? _streamIterator;
  SentenceAudioItem? _activeStreamingItem;
  List<String> _chapterSentences = [];
  List<TextSentence> _chapterSentenceModels = [];
  Map<int, List<TextSentence>> _chapterSentenceCache = {};
  List<int> _chapterSentenceCounts = [];
  int? _pendingSentenceIndex;
  bool _isReaderOpen = false;
  AppDestination _destination = AppDestination.library;
  String _searchQuery = '';
  bool _isStreaming = false;
  bool _isAdvancingStream = false;
  bool _completionHandledForActiveItem = false;
  int _streamGeneration = 0;
  Future<void> _streamTransitionFuture = Future<void>.value();
  Future<void>? _preparedStreamingFuture;
  SentenceAudioItem? _preparedStreamingItem;

  // Estados do Player de Áudio
  TTSAudioState _audioState = TTSAudioState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _currentSpeed = 1.0;
  int _activeSentenceIndex = 0;

  // Inscrições em Streams
  StreamSubscription<TTSAudioState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  final List<MOSRating> _savedMOSRatings = [];
  final SavedBookRepository _savedBookRepository = SavedBookRepository();
  List<SavedBookRecord> _savedBooks = [];
  SavedBookRecord? _activeSavedBook;
  Timer? _progressSaveTimer;
  SavedBookRecord? _pendingProgressRecord;
  Future<void>? _progressWriteFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Instancia o CompositeTTSEngine resiliente com Failover Automático
    _engine = _createEngine();
    _orchestrator =
        widget.orchestrator ?? PipelineOrchestrator(engine: _engine);

    // Usa AudioPlayerService nativo para reprodução de áudio real
    _audioPlayer = widget.audioPlayer ?? AudioPlayerService();

    _initAudioListeners();
    unawaited(_loadSavedBooks());
    unawaited(_loadEnginePreference());
  }

  Future<void> _loadEnginePreference() async {
    final type = await _enginePreference.load(
      hasSupertonic: _engine.hasSupertonic,
    );
    if (type == _engine.selectedType) return;
    try {
      await _engine.setEngineType(type);
      if (mounted) setState(() {});
    } on Object {
      await _engine.setEngineType(TTSEngineType.autoFailover);
      if (mounted) setState(() {});
    }
  }

  CompositeTTSEngine _createEngine() {
    final baseConfig = TTSConfig.defaultPtBr();
    String? modelDirectory = Platform.environment['SUPERTONIC_MODEL_DIR'];
    String? dllDirectory = Platform.environment['SHERPA_ONNX_DLL_DIR'];

    if (Platform.isWindows) {
      modelDirectory ??=
          '.planning/tmp/supertonic-extracted/sherpa-onnx-supertonic-3-tts-int8-2026-05-11';
      dllDirectory ??=
          '.planning/tmp/win-x64-shared-release/sherpa-onnx-v1.13.4-win-x64-shared-MD-Release-lib/lib';
    } else if (Platform.isAndroid && (modelDirectory == null || modelDirectory.trim().isEmpty)) {
      final candidates = <String>[
        '/storage/emulated/0/Android/data/com.example.tcc_tts_neural/files/supertonic',
        '/sdcard/Android/data/com.example.tcc_tts_neural/files/supertonic',
        '/storage/emulated/0/Download/supertonic',
        '/sdcard/Download/supertonic',
        '/storage/emulated/0/Download/sherpa-onnx-supertonic-3-tts-int8-2026-05-11',
        '/sdcard/Download/sherpa-onnx-supertonic-3-tts-int8-2026-05-11',
      ];
      for (final candidate in candidates) {
        final cfg = SupertonicConfig(modelDirectory: candidate);
        if (cfg.isInstalled) {
          if (candidate.contains('Download')) {
            final appSandbox = Directory('/storage/emulated/0/Android/data/com.example.tcc_tts_neural/files/supertonic');
            try {
              if (!appSandbox.existsSync()) appSandbox.createSync(recursive: true);
              for (final file in SupertonicConfig.requiredFiles) {
                final src = File('$candidate/$file');
                final dest = File('${appSandbox.path}/$file');
                if (src.existsSync() && (!dest.existsSync() || dest.lengthSync() != src.lengthSync())) {
                  src.copySync(dest.path);
                }
              }
              modelDirectory = appSandbox.path;
              break;
            } catch (_) {
              modelDirectory = candidate;
              break;
            }
          }
          modelDirectory = candidate;
          break;
        }
      }
    }

    if (modelDirectory == null || modelDirectory.trim().isEmpty) {
      return CompositeTTSEngine(config: baseConfig);
    }
    final supertonicConfig = SupertonicConfig(
      modelDirectory: modelDirectory,
      nativeLibraryDirectory: dllDirectory,
    );
    if (!supertonicConfig.isInstalled) {
      return CompositeTTSEngine(config: baseConfig);
    }
    return CompositeTTSEngine(
      config: baseConfig,
      supertonicEngine: SupertonicOnnxEngine(
        config: baseConfig,
        supertonicConfig: supertonicConfig,
      ),
    );
  }

  Future<void> _loadSavedBooks() async {
    try {
      final books = await _savedBookRepository.list();
      if (mounted) setState(() => _savedBooks = books);
    } on Object {
      // A biblioteca vazia continua utilizável se o armazenamento não estiver disponível.
    }
  }

  void _initAudioListeners() {
    _stateSub = _audioPlayer.stateStream.listen((state) {
      if (mounted) setState(() => _audioState = state);
      if (state == TTSAudioState.completed &&
          _isStreaming &&
          !_completionHandledForActiveItem) {
        _completionHandledForActiveItem = true;
        unawaited(_handleAudioCompleted());
      }
    });

    _posSub = _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _updateActiveSentenceIndex(pos);
        });
      }
    });

    _durSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => _totalDuration = dur);
      }
    });
  }

  void _updateActiveSentenceIndex(Duration pos) {
    if (_lastResult == null || _lastResult!.items.isEmpty) return;

    final timeline = _lastResult!.timeline;
    for (int i = 0; i < timeline.length; i++) {
      if (pos < timeline[i].end || i == timeline.length - 1) {
        if (_activeSentenceIndex != i) {
          setState(() => _activeSentenceIndex = i);
          unawaited(_persistReadingProgress());
        }
        return;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressSaveTimer?.cancel();
    unawaited(_persistReadingProgress());
    unawaited(_flushProgressWrites());
    unawaited(_stopStreamingPipeline());
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _audioPlayer.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistReadingProgress());
      unawaited(_flushProgressWrites());
    }
  }

  Future<void> _persistReadingProgress() async {
    final record = _activeSavedBook;
    final book = _loadedBook;
    final chapter = _currentChapter;
    if (record == null || book == null || chapter == null) return;

    final currentCount = _chapterSentenceModels.length;
    final beforeCount = _chapterSentenceCounts
        .take(chapter.index)
        .fold<int>(0, (sum, count) => sum + count);
    final totalCount = _chapterSentenceCounts.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final completedInChapter = currentCount == 0
        ? 0
        : (_activeSentenceIndex + 1).clamp(0, currentCount).toInt();
    final absolute = beforeCount + completedInChapter;
    final updated = record.copyWith(
      chapterIndex: chapter.index,
      sentenceIndex: _activeSentenceIndex,
      progress: totalCount == 0
          ? 0
          : (absolute / totalCount).clamp(0.0, 1.0).toDouble(),
      updatedAt: DateTime.now(),
    );
    _activeSavedBook = updated;
    _pendingProgressRecord = updated;
    _savedBooks = [
      updated,
      ..._savedBooks.where((item) => item.id != updated.id),
    ];
    if (mounted && !_isReaderOpen) setState(() {});
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_flushProgressWrites());
    });
  }

  Future<void> _flushProgressWrites() async {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    if (_progressWriteFuture != null) {
      await _progressWriteFuture;
      return;
    }
    final future = _drainProgressWrites();
    _progressWriteFuture = future;
    try {
      await future;
    } finally {
      if (identical(_progressWriteFuture, future)) _progressWriteFuture = null;
    }
  }

  Future<void> _drainProgressWrites() async {
    while (_pendingProgressRecord != null) {
      final record = _pendingProgressRecord!;
      _pendingProgressRecord = null;
      await _savedBookRepository.update(record);
    }
  }

  Future<void> _openSavedBook(SavedBookRecord record) async {
    final saved = await _savedBookRepository.load(record.id);
    if (saved == null) {
      await _loadSavedBooks();
      return;
    }
    try {
      final book = widget.importer.importBytes(
        name: saved.record.fileName,
        bytes: saved.bytes,
      );
      final chapterIndex =
          saved.record.chapterIndex.clamp(0, book.chapters.length - 1).toInt();
      setState(() {
        _loadedBook = book;
        _buildChapterSentenceCache();
        _activeSavedBook = saved.record;
        _currentChapter = book.chapters[chapterIndex];
        _prepareChapterSentences();
        _activeSentenceIndex = saved.record.sentenceIndex
            .clamp(
              0,
              _chapterSentenceModels.isEmpty
                  ? 0
                  : _chapterSentenceModels.length - 1,
            )
            .toInt();
        _pendingSentenceIndex = null;
        _lastResult = null;
        _isReaderOpen = true;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    }
  }

  void _prepareChapterSentences() {
    final chapter = _currentChapter;
    if (_chapterSentenceCache.isEmpty && _loadedBook != null) {
      _buildChapterSentenceCache();
    }
    _chapterSentenceModels = chapter == null
        ? []
        : _chapterSentenceCache[chapter.index] ?? const <TextSentence>[];
    _chapterSentences = _chapterSentenceModels
        .map((sentence) => sentence.text)
        .toList(growable: false);
  }

  void _buildChapterSentenceCache() {
    final book = _loadedBook;
    if (book == null) {
      _chapterSentenceCache = {};
      _chapterSentenceCounts = [];
      return;
    }
    _chapterSentenceCache = {
      for (final chapter in book.chapters)
        chapter.index: SentenceSegmenter.segment(chapter.cleanText),
    };
    _chapterSentenceCounts = book.chapters
        .map((chapter) => _chapterSentenceCache[chapter.index]!.length)
        .toList(growable: false);
  }

  Future<void> _closeReader() async {
    await _persistReadingProgress();
    await _flushProgressWrites();
    await _serializeStreamTransition(() async {
      await _stopStreamingPipelineUnlocked();
      if (!mounted) return;
      setState(() {
        _isReaderOpen = false;
        _pendingSentenceIndex = null;
      });
    });
  }

  Future<void> _changeChapter(EpubChapter chapter) {
    return _serializeStreamTransition(() async {
      await _stopStreamingPipelineUnlocked();
      if (!mounted) return;
      setState(() {
        _currentChapter = chapter;
        _prepareChapterSentences();
        _pendingSentenceIndex = null;
        _activeSentenceIndex = 0;
      });
      await _persistReadingProgress();
    });
  }

  void _selectSentence(int index) {
    if (index < 0 || index >= _chapterSentences.length) return;
    setState(() => _pendingSentenceIndex = index);
  }

  Future<void> _confirmSentenceSelection() async {
    final selected = _pendingSentenceIndex;
    if (selected == null) return;
    setState(() => _pendingSentenceIndex = null);
    await _runMvpPipeline(startSentenceIndex: selected);
  }

  Future<void> _runMvpPipelineUnlocked({int startSentenceIndex = 0}) async {
    if (_loadedBook == null || _currentChapter == null) return;

    if (!_isReaderOpen) {
      setState(() => _isReaderOpen = true);
    }
    await _stopStreamingPipelineUnlocked();
    final queue = CircularAudioBuffer(maxItems: 3);
    final iterator = StreamIterator<SentenceAudioItem>(
      _orchestrator.processChapterStream(
        book: _loadedBook!,
        chapter: _currentChapter!,
        queue: queue,
        startSentenceIndex: startSentenceIndex,
      ),
    );

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastResult = null;
      _activeSentenceIndex = startSentenceIndex;
      _streamQueue = queue;
      _streamIterator = iterator;
      _activeStreamingItem = null;
      _isStreaming = true;
    });

    final currentGen = _streamGeneration;
    await _advanceStreamingSentence(
      currentGen,
      iterator,
      queue,
    );
  }

  // ignore: unused_element
  Future<void> _advanceStreamingSentenceLegacy() async {
    if (_isAdvancingStream || !_isStreaming) return;
    _isAdvancingStream = true;
    try {
      final iterator = _streamIterator;
      final queue = _streamQueue;
      if (iterator == null || queue == null) return;

      final hasNext = await iterator.moveNext();
      if (!hasNext) {
        final active = _activeStreamingItem;
        if (active != null) {
          queue.release(active);
        }
        _activeStreamingItem = null;
        _isStreaming = false;
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _importStatus = 'Leitura concluída';
          });
        }
        await iterator.cancel();
        queue.dispose();
        _streamIterator = null;
        _streamQueue = null;
        return;
      }

      final item = iterator.current;
      final previous = _activeStreamingItem;
      if (previous != null) queue.release(previous);
      _activeStreamingItem = item;
      _completionHandledForActiveItem = false;
      await _audioPlayer.loadAudioBuffer(item.audio);
      if (mounted) {
        setState(() {
          _activeSentenceIndex = item.rawSentence.index;
          _importStatus = 'Frase ${item.rawSentence.index + 1} em reprodução';
          _isProcessing = false;
        });
      }
      unawaited(_persistReadingProgress());
      await _audioPlayer.play();
    } catch (error) {
      _isStreaming = false;
      await _stopStreamingPipeline();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = error.toString();
          _importStatus = 'Falha durante a leitura';
        });
      }
    } finally {
      _isAdvancingStream = false;
    }
  }

  Future<void> _stopStreamingPipelineUnlocked() async {
    ++_streamGeneration;
    _isStreaming = false;
    final active = _activeStreamingItem;
    final prepared = _preparedStreamingItem;
    final iterator = _streamIterator;
    final queue = _streamQueue;
    _streamIterator = null;
    _streamQueue = null;
    _activeStreamingItem = null;
    _preparedStreamingItem = null;
    _preparedStreamingFuture = null;
    if (active != null) {
      queue?.release(active);
    }
    if (prepared != null && !identical(prepared, active)) {
      queue?.release(prepared);
    }
    queue?.cancel();
    if (iterator != null) await iterator.cancel();
    await _audioPlayer.stop();
    queue?.dispose();
  }

  Future<void> _serializeStreamTransition(Future<void> Function() action) {
    final operation = _streamTransitionFuture.then<void>(
      (_) => action(),
      onError: (_, __) => action(),
    );
    _streamTransitionFuture = operation.catchError((_) {});
    return operation;
  }

  Future<void> _runMvpPipeline({int startSentenceIndex = 0}) {
    return _serializeStreamTransition(
      () => _runMvpPipelineUnlocked(startSentenceIndex: startSentenceIndex),
    );
  }

  Future<void> _stopStreamingPipeline() {
    return _serializeStreamTransition(_stopStreamingPipelineUnlocked);
  }

  bool _isCurrentStream(
    int generation,
    StreamIterator<SentenceAudioItem> iterator,
    CircularAudioBuffer queue,
  ) =>
      mounted &&
      _isStreaming &&
      generation == _streamGeneration &&
      identical(iterator, _streamIterator) &&
      identical(queue, _streamQueue);

  Future<void> _advanceStreamingSentence(
    int generation,
    StreamIterator<SentenceAudioItem> iterator,
    CircularAudioBuffer queue,
  ) async {
    if (!_isCurrentStream(generation, iterator, queue)) return;
    try {
      SentenceAudioItem? item;
      final preparation = _preparedStreamingFuture;
      if (preparation == null) {
        final hasNext = await iterator.moveNext();
        if (!_isCurrentStream(generation, iterator, queue)) return;
        if (hasNext) item = iterator.current;
      } else {
        await preparation;
        if (!_isCurrentStream(generation, iterator, queue)) return;
        item = _preparedStreamingItem;
        _preparedStreamingItem = null;
        _preparedStreamingFuture = null;
      }
      if (item == null) {
        await _finishStreamingSentence(generation, iterator, queue);
        return;
      }
      await _playStreamingItem(generation, iterator, queue, item);
    } catch (error) {
      if (!_isCurrentStream(generation, iterator, queue)) return;
      await _stopStreamingPipelineUnlocked();
      if (mounted && generation != _streamGeneration) {
        setState(() {
          _isProcessing = false;
          _errorMessage = error.toString();
          _importStatus = 'Falha durante a leitura';
        });
      }
    }
  }

  Future<void> _playStreamingItem(
    int generation,
    StreamIterator<SentenceAudioItem> iterator,
    CircularAudioBuffer queue,
    SentenceAudioItem item,
  ) async {
    if (!_isCurrentStream(generation, iterator, queue)) {
      queue.release(item);
      return;
    }
    final previous = _activeStreamingItem;
    if (previous != null) queue.release(previous);
    _activeStreamingItem = item;
    _completionHandledForActiveItem = false;
    await _audioPlayer.loadAudioBuffer(item.audio);
    if (!_isCurrentStream(generation, iterator, queue) ||
        !identical(item, _activeStreamingItem)) {
      return;
    }
    setState(() {
      _activeSentenceIndex = item.rawSentence.index;
      _importStatus = 'Frase ${item.rawSentence.index + 1} em reprodução';
      _isProcessing = false;
    });
    unawaited(_persistReadingProgress());
    await _audioPlayer.play();
    if (!_isCurrentStream(generation, iterator, queue) ||
        !identical(item, _activeStreamingItem)) {
      return;
    }
    _preparedStreamingFuture = _prepareNextStreamingItem(
      generation,
      iterator,
      queue,
    );
  }

  Future<void> _prepareNextStreamingItem(
    int generation,
    StreamIterator<SentenceAudioItem> iterator,
    CircularAudioBuffer queue,
  ) async {
    final hasNext = await iterator.moveNext();
    if (!_isCurrentStream(generation, iterator, queue)) return;
    if (hasNext) {
      _preparedStreamingItem = iterator.current;
    }
  }

  Future<void> _handleAudioCompleted() async {
    final generation = _streamGeneration;
    final iterator = _streamIterator;
    final queue = _streamQueue;
    final active = _activeStreamingItem;
    if (iterator == null ||
        queue == null ||
        active == null ||
        !_isCurrentStream(generation, iterator, queue) ||
        !identical(active, _activeStreamingItem)) {
      return;
    }
    await _advanceStreamingSentence(generation, iterator, queue);
  }

  Future<void> _finishStreamingSentence(
    int generation,
    StreamIterator<SentenceAudioItem> iterator,
    CircularAudioBuffer queue,
  ) async {
    if (!_isCurrentStream(generation, iterator, queue)) {
      return;
    }
    await _stopStreamingPipelineUnlocked();
    if (mounted && generation != _streamGeneration) {
      setState(() {
        _isProcessing = false;
        _importStatus = 'Leitura concluída';
      });
    }
  }

  Future<void> _importEpub() async {
    setState(() {
      _importStatus = 'Selecionando EPUB...';
      _errorMessage = null;
    });
    try {
      final selected = await widget.picker.pickEpub();
      if (!mounted) return;
      if (selected == null) {
        setState(() => _importStatus = 'Importação cancelada');
        return;
      }
      setState(() => _importStatus = 'Lendo EPUB...');
      final book = widget.importer.importDocument(selected);
      if (!mounted) return;
      SavedBookRecord? savedRecord;
      try {
        savedRecord = await _savedBookRepository.saveNew(
          fileName: selected.name,
          bytes: selected.bytes,
          book: book,
        );
      } on Object {
        // A leitura desta sessão não depende do armazenamento persistente.
      }
      final restoredChapter = savedRecord != null && book.chapters.isNotEmpty
          ? book.chapters[savedRecord.chapterIndex
              .clamp(0, book.chapters.length - 1)
              .toInt()]
          : book.chapterOne;
      setState(() {
        _loadedBook = book;
        _chapterSentenceCache = {};
        _activeSavedBook = savedRecord;
        final storedRecord = savedRecord;
        if (storedRecord != null) {
          _savedBooks = [
            storedRecord,
            ..._savedBooks.where((item) => item.id != storedRecord.id),
          ];
        }
        _currentChapter = restoredChapter;
        _prepareChapterSentences();
        _activeSentenceIndex = savedRecord?.sentenceIndex
                .clamp(
                  0,
                  _chapterSentenceModels.isEmpty
                      ? 0
                      : _chapterSentenceModels.length - 1,
                )
                .toInt() ??
            0;
        _pendingSentenceIndex = null;
        _isReaderOpen = true;
        _lastResult = null;
        _importStatus = 'EPUB importado com sucesso';
      });
    } on EpubImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _importStatus = 'Falha na importação';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _importStatus = 'Falha na importação';
      });
    } on DocumentSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _importStatus = 'Falha ao ler o arquivo selecionado';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível importar este EPUB.';
        _importStatus = 'Falha na importação';
      });
    }
  }

  Future<void> _switchEngine(TTSEngineType type) async {
    await _stopStreamingPipeline();
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      if (_engine.selectedType == type) {
        await _engine.initialize();
      } else {
        await _engine.setEngineType(type);
      }
      await _enginePreference.save(type);
      if (!mounted) return;
      setState(() => _isProcessing = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _showMOSDialog() {
    if (_lastResult == null) return;
    showDialog(
      context: context,
      builder: (context) => MOSEvaluationDialog(
        sampleText: _currentChapter?.plainText ?? '',
        onSubmitted: (rating) {
          setState(() {
            _savedMOSRatings.add(rating);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Avaliação MOS salva com sucesso! Média: ${rating.averageScore.toStringAsFixed(2)} estrelas.',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReaderScaffold() {
    final chapter = _currentChapter;
    final book = _loadedBook;
    if (chapter == null || book == null) return const SizedBox.shrink();

    void playPause() {
      if (_audioState == TTSAudioState.playing) {
        unawaited(_audioPlayer.pause());
      } else if (!_isStreaming) {
        unawaited(_runMvpPipeline(startSentenceIndex: _activeSentenceIndex));
      } else {
        unawaited(_audioPlayer.play());
      }
    }

    return ReaderPage(
      book: book,
      chapter: chapter,
      sentences: _chapterSentenceModels,
      activeIndex: _activeSentenceIndex,
      pendingIndex: _pendingSentenceIndex,
      isProcessing: _isProcessing,
      synthesisStatus: _importStatus,
      rtf: _lastResult?.overallRtf,
      playerService: _audioPlayer,
      audioState: _audioState,
      currentPosition: _currentPosition,
      totalDuration: _totalDuration,
      currentSpeed: _currentSpeed,
      maxSpeed: _engine.activeType == TTSEngineType.supertonic ||
              _engine.selectedType == TTSEngineType.supertonic
          ? 1.5
          : 2.0,
      onBack: () => unawaited(_closeReader()),
      onChapterChanged: (selected) => unawaited(_changeChapter(selected)),
      onSentenceSelected: _selectSentence,
      onCancelSelection: () => setState(() => _pendingSentenceIndex = null),
      onConfirmSelection: () => unawaited(_confirmSentenceSelection()),
      onPlayPause: playPause,
      onStop: () => unawaited(_stopStreamingPipeline()),
      onSeek: (position) => unawaited(_audioPlayer.seek(position)),
      onSpeedChanged: (speed) {
        setState(() => _currentSpeed = speed);
        unawaited(_audioPlayer.setSpeed(speed));
      },
      onOpenMos: _showMOSDialog,
    );
  }

  Future<void> _deleteSavedBook(SavedBookRecord record) async {
    await _savedBookRepository.delete(record.id);
    if (!mounted) return;
    setState(() {
      _savedBooks = _savedBooks
          .where((item) => item.id != record.id)
          .toList(growable: false);
      if (_activeSavedBook?.id == record.id) {
        _activeSavedBook = null;
        _loadedBook = null;
        _currentChapter = null;
        _chapterSentenceCache = {};
        _chapterSentenceCounts = [];
      }
    });
  }

  Widget _buildDestinationBody() {
    if (_destination == AppDestination.settings) {
      return SettingsView(
        engineTypes: _engine.availableEngineTypes,
        selectedType: _engine.selectedType,
        activeEngineLabel:
            _engine.activeType?.label ?? 'Nenhum motor inicializado',
        isProcessing: _isProcessing,
        onEngineChanged: (type) => unawaited(_switchEngine(type)),
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        themePalette: widget.themePalette,
        onThemePaletteChanged: widget.onThemePaletteChanged,
      );
    }
    return LibraryView(
      books: _savedBooks,
      importStatus: _importStatus,
      engineStatus: _engine.activeType?.label ?? _engine.selectedType.label,
      errorMessage: _errorMessage,
      isProcessing: _isProcessing,
      searchMode: _destination == AppDestination.search,
      searchQuery: _searchQuery,
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      onImport: () => unawaited(_importEpub()),
      onOpenBook: (record) => unawaited(_openSavedBook(record)),
      onDeleteBook: (record) => unawaited(_deleteSavedBook(record)),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    return AppBar(
      title: const Text('VozLume'),
      actions: [
        if (_savedMOSRatings.isNotEmpty)
          Chip(
            avatar: Icon(Icons.star,
                color: ext?.grifo ?? theme.colorScheme.primary, size: 16),
            label: Text(
              'MOS ${(_savedMOSRatings.map((rating) => rating.averageScore).reduce((a, b) => a + b) / _savedMOSRatings.length).toStringAsFixed(2)}',
            ),
          ),
        if (_lastResult != null)
          IconButton(
            icon: Icon(Icons.assignment_outlined,
                color: ext?.moss ?? theme.colorScheme.primary),
            tooltip: 'Ver relatório de desempenho',
            onPressed: _showAcademicReportDialog,
          ),
        IconButton(
          icon: Icon(Icons.info_outline,
              color: ext?.textSoft ?? theme.colorScheme.onSurface),
          tooltip: 'Sobre a arquitetura',
          onPressed: _showArchitectureInfo,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isReaderOpen) return _buildReaderScaffold();
    return ResponsiveNavigationShell(
      destination: _destination,
      onDestinationChanged: (destination) =>
          setState(() => _destination = destination),
      appBar: _buildHomeAppBar(),
      body: _buildDestinationBody(),
    );
  }

  void _showAcademicReportDialog() {
    if (_lastResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Relatório Oficial de Desempenho (TCC)',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            _lastResult!.generateAcademicReport(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFFE0F2FE),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  void _showArchitectureInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fase 6: Audio Player & MOS Evaluation (Milestone 2)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• AudioPlayerService (audioplayers wrapper).'),
              Text(
                '• SentenceHighlightView (sincronização de sentença e áudio em tempo real).',
              ),
              Text(
                '• MOSEvaluationDialog (avaliação perceptual do orientador de 1 a 5 estrelas).',
              ),
              Text('• Controle de velocidade (0.75x - 2.0x) e Seekbar.'),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
