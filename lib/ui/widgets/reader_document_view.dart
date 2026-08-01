import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/text/sentence_model.dart';
import '../../core/document/epub_model.dart';
import '../../core/text/sentence_segmenter.dart';
import '../app_theme.dart';

/// Renderiza o capítulo como texto contínuo; as frases recebem apenas uma
/// marcação visual para sincronização, sem serem transformadas em cartões.
class ReaderDocumentView extends StatefulWidget {
  final List<TextSentence> sentences;
  final int activeIndex;
  final int? pendingIndex;
  final ValueChanged<int>? onSentenceTap;
  final List<EpubContentBlock> contentBlocks;

  const ReaderDocumentView({
    super.key,
    required this.sentences,
    required this.activeIndex,
    this.pendingIndex,
    this.onSentenceTap,
    this.contentBlocks = const [],
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
    InlineSpan spanFor(TextSentence sentence) {
      final isActive = sentence.index == widget.activeIndex;
      final isPending = sentence.index == widget.pendingIndex;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onSentenceTap?.call(sentence.index);
      _recognizers.add(recognizer);
      return TextSpan(
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
      );
    }

    for (final sentence in sentences) {
      spans.add(spanFor(sentence));
    }

    if (widget.contentBlocks.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: RichText(text: TextSpan(children: spans)),
      );
    }

    var sentenceOffset = 0;
    final children = <Widget>[];
    for (final block in widget.contentBlocks) {
      if (block case EpubTextBlock(:final text)) {
        final count = SentenceSegmenter.segment(text).length;
        final blockSentences = sentences
            .skip(sentenceOffset)
            .take(count)
            .toList(growable: false);
        sentenceOffset += blockSentences.length;
        if (blockSentences.isNotEmpty) {
          children.add(RichText(
            text: TextSpan(children: blockSentences.map(spanFor).toList()),
          ));
        }
      } else if (block case EpubImageBlock(:final bytes, :final resourcePath)) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Semantics(
            image: true,
            label: 'Imagem do EPUB: $resourcePath',
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}
