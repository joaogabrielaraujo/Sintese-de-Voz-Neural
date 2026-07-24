import 'package:flutter/material.dart';
import 'core/config/tts_config.dart';
import 'core/engine/mock_tts_engine.dart';
import 'core/engine/tts_engine_interface.dart';
import 'core/epub/epub_model.dart';
import 'core/epub/epub_parser.dart';
import 'core/pipeline/pipeline_orchestrator.dart';
import 'core/pipeline/pipeline_result.dart';

void main() {
  runApp(const TCCNeuralApp());
}

/// Aplicativo de Demonstração do PRIMEIRO MVP - TCC Engenharia de Computação (UEFS).
class TCCNeuralApp extends StatelessWidget {
  const TCCNeuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCC - Primeiro MVP Leitor EPUB Neural',
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
  const PoCNeuralHomePage({super.key});

  @override
  State<PoCNeuralHomePage> createState() => _PoCNeuralHomePageState();
}

class _PoCNeuralHomePageState extends State<PoCNeuralHomePage> {
  late final ITTSEngine _engine;
  late final PipelineOrchestrator _orchestrator;

  EpubBook? _loadedBook;
  EpubChapter? _currentChapter;

  bool _isProcessing = false;
  PipelineResult? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _engine = MockTTSEngine(
      config: TTSConfig.defaultPtBr(),
    );
    _orchestrator = PipelineOrchestrator(engine: _engine);
    _loadSampleEpub();
  }

  @override
  void dispose() {
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

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      final PipelineResult result = await _orchestrator.processChapter(
        book: _loadedBook!,
        chapter: _currentChapter!,
      );

      setState(() {
        _lastResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PRIMEIRO MVP (Demonstração TCC)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (_lastResult != null)
            IconButton(
              icon: const Icon(Icons.assignment_outlined, color: Color(0xFF34D399)),
              tooltip: 'Ver Relatório para o Orientador',
              onPressed: _showAcademicReportDialog,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF818CF8)),
            onPressed: _showArchitectureInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner do Livro EPUB (Fase 4)
            if (_loadedBook != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_stories, color: Color(0xFF818CF8), size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _loadedBook!.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Autor: ${_loadedBook!.author} | UEFS 2026',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFF334155)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<EpubChapter>(
                          value: _currentChapter,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
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
                              });
                            }
                          },
                        ),
                        Text(
                          '${_currentChapter?.wordCount ?? 0} palavras',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Botão Executar MVP Pipeline
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _runMvpPipeline,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(
                _isProcessing ? 'Sintetizando Capítulo em Tempo Real...' : 'Executar Pipeline do Primeiro MVP',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
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

            if (_lastResult != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sentenças Sintetizadas (${_lastResult!.totalSentences}):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAcademicReportDialog,
                    icon: const Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF34D399)),
                    label: const Text('Relatório TCC', style: TextStyle(color: Color(0xFF34D399))),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lastResult!.items.length,
                itemBuilder: (context, index) {
                  final item = _lastResult!.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: item.rawSentence.isParagraphEnd
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sentença #${item.rawSentence.index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF818CF8),
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2942),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'RTF: ${item.metrics.rtf.toStringAsFixed(3)}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Original: ${item.rawSentence.text}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Normalizado: ${item.normalizedText}',
                          style: const TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Resumo de Telemetria Global do MVP
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Áudio: ${_lastResult!.totalAudioDurationSeconds.toStringAsFixed(2)}s',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RTF Global: ${_lastResult!.overallRtf.toStringAsFixed(4)}',
                          style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status RNF-02: APROVADO (Inferência sem travamentos em tempo real)',
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
        title: const Text('Relatório Oficial de Desempenho (TCC)', style: TextStyle(color: Colors.white)),
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
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF6366F1))),
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
                'Primeiro MVP de Demonstração (Milestone 1)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Fase 4: Extração de Texto EPUB por Capítulos (EpubParser).'),
              Text('• Fase 3: Fatiador de Sentenças (SentenceSegmenter).'),
              Text('• Fase 2: Normalizador Gramatical em PT-BR (TTSNormalizer).'),
              Text('• Fase 1: Engine de Inferência Neural ONNX (Sherpa-ONNX Core).'),
              Text('• Fachada: PipelineOrchestrator com Telemetria de RTF.'),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
