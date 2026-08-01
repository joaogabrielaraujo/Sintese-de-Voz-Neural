import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/text/sentence_model.dart';

/// Renderiza o capítulo como texto contínuo; as frases recebem apenas uma
/// marcação visual para sincronização, sem serem transformadas em cartões.
class ReaderDocumentView extends StatefulWidget {
  final List<TextSentence> sentences;
  final int activeIndex;
  final int? pendingIndex;
  final ValueChanged<int>? onSentenceTap;

  const ReaderDocumentView({
    super.key,
    required this.sentences,
    required this.activeIndex,
    this.pendingIndex,
    this.onSentenceTap,
  });

  @override
  State<ReaderDocumentView> createState() => _ReaderDocumentViewState();
}

class _ReaderDocumentViewState extends State<ReaderDocumentView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final sentences = widget.sentences;
    if (sentences.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo para leitura.'));
    }

    final spans = <InlineSpan>[];
    for (final sentence in sentences) {
      final isActive = sentence.index == widget.activeIndex;
      final isPending = sentence.index == widget.pendingIndex;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onSentenceTap?.call(sentence.index);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: '${sentence.text}${sentence.isParagraphEnd ? '\n\n' : ' '}',
          recognizer: recognizer,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.65,
            backgroundColor: isActive
                ? const Color(0xFF6366F1).withOpacity(0.35)
                : isPending
                    ? const Color(0xFFF59E0B).withOpacity(0.25)
                    : Colors.transparent,
            fontWeight: isActive || isPending
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
