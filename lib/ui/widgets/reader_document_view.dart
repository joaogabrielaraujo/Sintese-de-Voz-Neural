import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/text/sentence_model.dart';
import '../app_theme.dart';

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
      return const Center(
        child: Text('Nenhum conteúdo para leitura.',
            style: TextStyle(color: AppColors.paperDim)),
      );
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
          style: AppTextStyles.reading.copyWith(
            color: isActive || isPending ? AppColors.paper : AppColors.paperDim,
            backgroundColor: isActive
                ? AppColors.amberDim.withValues(alpha: 0.8)
                : isPending
                    ? AppColors.tealDim.withValues(alpha: 0.8)
                    : Colors.transparent,
            decoration: isActive || isPending ? TextDecoration.underline : null,
            decorationColor: isActive ? AppColors.amber : AppColors.teal,
            decorationStyle: isPending
                ? TextDecorationStyle.dashed
                : TextDecorationStyle.solid,
            decorationThickness: 2,
            fontWeight:
                isActive || isPending ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
