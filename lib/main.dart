import 'dart:async';
import 'package:flutter/material.dart';
import 'core/audio/audio_player_service.dart';
import 'core/audio/audio_player_service_interface.dart';
import 'core/config/tts_config.dart';
import 'core/engine/composite_tts_engine.dart';
import 'core/engine/tts_engine_type.dart';
import 'core/document/epub_model.dart';
import 'core/document/epub_parser.dart';
import 'core/document/epub_bytes_importer.dart';
import 'core/document/selected_document.dart';
import 'core/memory/circular_audio_buffer.dart';
import 'core/memory/sentence_audio_item.dart';
import 'core/metrics/mos_rating_model.dart';
import 'core/pipeline/pipeline_orchestrator.dart';
import 'core/pipeline/pipeline_result.dart';
import 'ui/widgets/audio_player_control_bar.dart';
import 'ui/widgets/mos_evaluation_dialog.dart';
import 'ui/widgets/sentence_highlight_view.dart';

void main() {
  runApp(const TCCNeuralApp());
}

/// Aplicativo de Leitor EPUB Neural & Player de Áudio (Fase 6 - TCC UEFS).
class TCCNeuralApp extends StatelessWidget {
  const TCCNeuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCC - Leitor EPUB Neural & Player de Áudio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate Escuro
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Índigo
          brightness: Brightness.dark,
        ),
      ),
      home: const PoCNeuralHomePage(),
    );
  }
}

class PoCNeuralHomePage extends StatefulWidget {
  final EpubDocumentPicker picker;
  final EpubBytesImporter importer;

  const PoCNeuralHomePage({
    super.key,
    this.picker = const NativeEpubDocumentPicker(),
    this.importer = const EpubBytesImporter(),
  });

  @override
  State<PoCNeuralHomePage> createState() => _PoCNeuralHomePageState();
}

class _PoCNeuralHomePageState extends State<PoCNeuralHomePage> {
  static const _selectableEngineTypes = <TTSEngineType>[
    TTSEngineType.autoFailover,
    TTSEngineType.sherpaOnnx,
    TTSEngineType.sherpaOnnxCli,
  ];

  late final CompositeTTSEngine _engine;
  late final PipelineOrchestrator _orchestrator;
  late final IAudioPlayerService _audioPlayer;

  EpubBook? _loadedBook;
  EpubChapter? _currentChapter;

  bool _isProcessing = false;
  PipelineResult? _lastResult;
  String? _errorMessage;
  String _importStatus = 'Livro de demonstração carregado';
  CircularAudioBuffer? _streamQueue;
  StreamIterator<SentenceAudioItem>? _streamIterator;
  SentenceAudioItem? _activeStreamingItem;
  final List<String> _streamingVisibleSentences = [];
  bool _isStreaming = false;
  bool _isAdvancingStream = false;

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

  @override
  void initState() {
    super.initState();
    // Instancia o CompositeTTSEngine resiliente com Failover Automático
    _engine = CompositeTTSEngine(config: TTSConfig.defaultPtBr());
    _orchestrator = PipelineOrchestrator(engine: _engine);

    // Usa AudioPlayerService nativo para reprodução de áudio real
    _audioPlayer = AudioPlayerService();

    _initAudioListeners();
    _loadSampleEpub();
  }

  void _initAudioListeners() {
    _stateSub = _audioPlayer.stateStream.listen((state) {
      if (mounted) setState(() => _audioState = state);
      if (state == TTSAudioState.completed && _isStreaming) {
        unawaited(_advanceStreamingSentence());
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
        }
        return;
      }
    }
  }

  @override
  void dispose() {
    unawaited(_stopStreamingPipeline());
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _audioPlayer.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _loadSampleEpub() {
    final Map<String, String> mockEpubArchive = {
      'META-INF/container.xml': '''
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles><rootfile full-path="OEBPS/content.opf"/></rootfiles>
        </container>
      ''',
      'OEBPS/content.opf': '''
        <package version="3.0">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>Síntese de Voz Neural em Edge Computing</dc:title>
            <dc:creator>João Gabriel A. Almeida</dc:creator>
            <dc:language>pt-BR</dc:language>
          </metadata>
          <manifest>
            <item id="chap1" href="chap1.xhtml"/>
            <item id="chap2" href="chap2.xhtml"/>
          </manifest>
          <spine>
            <itemref idref="chap1"/>
            <itemref idref="chap2"/>
          </spine>
        </package>
      ''',
      'OEBPS/chap1.xhtml': r'''
        <html>
          <body>
            <h1>Capítulo 1: Fundamentação e Objetivos</h1>
            <p>Em 24/07/2026, o Dr. Matheus aprovou a 1ª versão do TCC na UEFS custando R$ 150,00.</p>
            <p>A síntese de voz neural opera 100% offline no dispositivo móvel com RTF &lt; 1.0! Esta arquitetura garante consumo constante de memória RAM.</p>
          </body>
        </html>
      ''',
      'OEBPS/chap2.xhtml': '''
        <html>
          <body>
            <h1>Capítulo 2: Arquitetura Modular</h1>
            <p>Os módulos core foram desenvolvidos em Dart e divididos em 4 camadas desacopladas.</p>
          </body>
        </html>
      ''',
    };

    final EpubBook book = EpubParser.parseArchive(mockEpubArchive);
    setState(() {
      _loadedBook = book;
      _currentChapter = book.chapterOne;
    });
  }

  Future<void> _runMvpPipeline() async {
    if (_loadedBook == null || _currentChapter == null) return;

    await _stopStreamingPipeline();
    final queue = CircularAudioBuffer(maxItems: 3);
    final iterator = StreamIterator<SentenceAudioItem>(
      _orchestrator.processChapterStream(
        book: _loadedBook!,
        chapter: _currentChapter!,
        queue: queue,
      ),
    );

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastResult = null;
      _activeSentenceIndex = 0;
      _streamQueue = queue;
      _streamIterator = iterator;
      _activeStreamingItem = null;
      _streamingVisibleSentences.clear();
      _isStreaming = true;
    });

    await _advanceStreamingSentence();
  }

  Future<void> _advanceStreamingSentence() async {
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
      _streamingVisibleSentences.add(item.rawSentence.text);
      if (_streamingVisibleSentences.length > 5) {
        _streamingVisibleSentences.removeAt(0);
      }

      await _audioPlayer.loadAudioBuffer(item.audio);
      if (mounted) {
        setState(() {
          _activeSentenceIndex = _streamingVisibleSentences.length - 1;
          _importStatus = 'Frase ${item.rawSentence.index + 1} em reprodução';
          _isProcessing = false;
        });
      }
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

  Future<void> _stopStreamingPipeline() async {
    _isStreaming = false;
    final active = _activeStreamingItem;
    final iterator = _streamIterator;
    final queue = _streamQueue;
    _streamIterator = null;
    _streamQueue = null;
    _activeStreamingItem = null;
    if (active != null) {
      queue?.release(active);
    }
    queue?.cancel();
    if (iterator != null) await iterator.cancel();
    queue?.dispose();
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
      setState(() {
        _loadedBook = book;
        _currentChapter = book.chapterOne;
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível importar este EPUB.';
        _importStatus = 'Falha na importação';
      });
    }
  }

  Future<void> _switchEngine(TTSEngineType type) async {
    await _audioPlayer.stop();
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

  @override
  Widget build(BuildContext context) {
    final sentencesList = _isStreaming
        ? _streamingVisibleSentences
        : (_lastResult?.items.map((i) => i.normalizedText).toList() ?? []);
    final activeEngineLabel =
        _engine.activeType?.label ?? 'Nenhum motor inicializado';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leitor EPUB & Player Neural (TCC UEFS)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (_savedMOSRatings.isNotEmpty)
            Chip(
              avatar: const Icon(
                Icons.star,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
              label: Text(
                'MOS: ${(_savedMOSRatings.map((r) => r.averageScore).reduce((a, b) => a + b) / _savedMOSRatings.length).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color(0xFF334155),
            ),
          if (_lastResult != null)
            IconButton(
              icon: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF34D399),
              ),
              tooltip: 'Ver Relatório para o Orientador',
              onPressed: _showAcademicReportDialog,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF818CF8)),
            onPressed: _showArchitectureInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner do Livro EPUB (Fase 4)
            if (_loadedBook != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories,
                          color: Color(0xFF818CF8),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _loadedBook!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Autor: ${_loadedBook!.author} | UEFS 2026',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFF334155)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<EpubChapter>(
                          value: _currentChapter,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                          ),
                          items: _loadedBook!.chapters.map((chap) {
                            return DropdownMenuItem(
                              value: chap,
                              child: Text(chap.title),
                            );
                          }).toList(),
                          onChanged: (selected) {
                            if (selected != null) {
                              setState(() {
                                _currentChapter = selected;
                                _lastResult = null;
                                unawaited(_stopStreamingPipeline());
                                _audioPlayer.stop();
                              });
                            }
                          },
                        ),
                        Text(
                          '${_currentChapter?.wordCount ?? 0} palavras',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _importEpub,
              icon: const Icon(Icons.file_open),
              label: const Text('Importar EPUB do dispositivo'),
            ),
            const SizedBox(height: 4),
            Text(
              _importStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),

            // Indicador de Motor TTS Neural Ativo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.record_voice_over,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Motor:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<TTSEngineType>(
                      value: _engine.selectedType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: _selectableEngineTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isProcessing
                          ? null
                          : (type) {
                              if (type != null) _switchEngine(type);
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ativo: $activeEngineLabel',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Botão Sintetizar Capítulo
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _runMvpPipeline,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                _isProcessing
                    ? 'Sintetizando Capítulo em Tempo Real...'
                    : 'Sintetizar & Reproduzir Áudio Neural',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Erro: $_errorMessage',
                  style: const TextStyle(color: Color(0xFFFCA5A5)),
                ),
              ),
            ],

            // ÁREA PRINCIPAL: Sentenças em destaque + Player de Áudio
            if (_lastResult != null) ...[
              const SizedBox(height: 12),
              Expanded(
                child: SentenceHighlightView(
                  sentences: sentencesList,
                  activeIndex: _activeSentenceIndex,
                  onSentenceTap: (index) {
                    if (_isStreaming || _lastResult == null) return;
                    setState(() => _activeSentenceIndex = index);
                    _audioPlayer.seek(_lastResult!.timeline[index].start);
                  },
                ),
              ),
              const SizedBox(height: 12),
              AudioPlayerControlBar(
                playerService: _audioPlayer,
                currentState: _audioState,
                currentPosition: _currentPosition,
                totalDuration: _totalDuration,
                currentSpeed: _currentSpeed,
                onPlayPausePressed: () {
                  if (_audioState == TTSAudioState.playing) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
                onStopPressed: () {
                  unawaited(_stopStreamingPipeline());
                  unawaited(_audioPlayer.stop());
                  if (mounted) setState(() => _isProcessing = false);
                },
                onSeekChanged: (pos) => _audioPlayer.seek(pos),
                onSpeedChanged: (speed) {
                  setState(() => _currentSpeed = speed);
                  _audioPlayer.setSpeed(speed);
                },
                onOpenMOSDialog: _showMOSDialog,
              ),
            ],
          ],
        ),
      ),
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
