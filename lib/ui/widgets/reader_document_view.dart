import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/document/epub_model.dart';
import '../../core/text/sentence_model.dart';
import '../../core/text/sentence_segmenter.dart';
import '../app_theme.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sentenceKeys = {};
  bool _userHasScrolledManually = false;

  @override
  void didUpdateWidget(ReaderDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      if (!_userHasScrolledManually) {
        _scrollToActiveSentence();
      }
    }
    if (oldWidget.pendingIndex != widget.pendingIndex && widget.pendingIndex != null) {
      _userHasScrolledManually = false;
      _scrollToActiveSentence();
    }
  }

  void _scrollToActiveSentence() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = widget.pendingIndex ?? widget.activeIndex;
      final key = _sentenceKeys[targetIndex];
      if (key?.currentContext != null) {
        final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
          alignment: 0.3,
        );
      }
    });
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final sentences = widget.sentences;
    if (sentences.isEmpty) {
      return Center(
        child: Text(
          'Nenhum conteúdo para leitura.',
          style: AppTextStyles.statusMono.copyWith(
            color: ext?.textWeak ?? theme.colorScheme.onSurface,
          ),
        ),
      );
    }

    InlineSpan spanFor(TextSentence sentence) {
      final isActive = sentence.index == widget.activeIndex;
      final isPending = sentence.index == widget.pendingIndex;
      final key = _sentenceKeys.putIfAbsent(sentence.index, () => GlobalKey());

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          setState(() => _userHasScrolledManually = false);
          widget.onSentenceTap?.call(sentence.index);
        };
      _recognizers.add(recognizer);

      final style = AppTextStyles.epubReading.copyWith(
        color: isActive
            ? (ext?.grifo ?? theme.colorScheme.primary)
            : isPending
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
        backgroundColor: isActive
            ? (ext?.grifo ?? theme.colorScheme.primary).withValues(alpha: 0.12)
            : isPending
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
        decoration: isActive
            ? TextDecoration.underline
            : isPending
                ? TextDecoration.underline
                : null,
        decorationColor: isActive
            ? (ext?.grifo ?? theme.colorScheme.primary)
            : theme.colorScheme.primary,
        decorationStyle: isPending
            ? TextDecorationStyle.dashed
            : TextDecorationStyle.wavy,
        decorationThickness: 2,
        fontWeight: isActive || isPending ? FontWeight.w600 : FontWeight.w400,
      );

      return WidgetSpan(
        child: Semantics(
          key: key,
          label: isActive
              ? 'Lendo agora: ${sentence.text}'
              : isPending
                  ? 'Selecionado para leitura: ${sentence.text}'
                  : sentence.text,
          child: Text.rich(
            TextSpan(
              text: '${sentence.text}${sentence.isParagraphEnd ? '\n\n' : ' '}',
              recognizer: recognizer,
              style: style,
            ),
          ),
        ),
      );
    }

    Widget content;
    if (widget.contentBlocks.isEmpty) {
      final spans = sentences.map(spanFor).toList(growable: false);
      content = RichText(text: TextSpan(children: spans));
    } else {
      var sentenceOffset = 0;
      final children = <Widget>[];
      for (final block in widget.contentBlocks) {
        if (block case EpubTextBlock(:final text)) {
          final blockSentences = SentenceSegmenter.segment(text);
          final spans = <InlineSpan>[];
          for (var i = 0; i < blockSentences.length; i++) {
            final globalIndex = sentenceOffset + i;
            if (globalIndex < sentences.length) {
              spans.add(spanFor(sentences[globalIndex]));
            }
          }
          sentenceOffset += blockSentences.length;
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RichText(text: TextSpan(children: spans)),
            ),
          );
        } else if (block case EpubImageBlock(:final bytes)) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: ExcludeSemantics(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        }
      }
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        _userHasScrolledManually = true;
        return false;
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: content,
          ),
        ),
      ),
    );
  }
}
