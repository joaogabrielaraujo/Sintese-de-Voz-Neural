import 'package:flutter/material.dart';

/// Componente visual para exibir as sentenças do texto com destaque em tempo real.
class SentenceHighlightView extends StatefulWidget {
  final List<String> sentences;
  final int activeIndex;
  final ValueChanged<int>? onSentenceTap;
  final int? pendingIndex;

  const SentenceHighlightView({
    super.key,
    required this.sentences,
    required this.activeIndex,
    this.onSentenceTap,
    this.pendingIndex,
  });

  @override
  State<SentenceHighlightView> createState() => _SentenceHighlightViewState();
}

class _SentenceHighlightViewState extends State<SentenceHighlightView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SentenceHighlightView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex &&
        widget.activeIndex >= 0 &&
        widget.activeIndex < widget.sentences.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final target = (widget.activeIndex * 92.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ).toDouble();
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentences = widget.sentences;
    if (sentences.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma sentença carregada para síntese.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: sentences.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final isSelected = index == widget.activeIndex;
        final isPending = index == widget.pendingIndex;
        return GestureDetector(
          onTap: () => widget.onSentenceTap?.call(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : isPending
                          ? const Color(0xFFF59E0B).withOpacity(0.14)
                      : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF818CF8)
                    : isPending
                        ? const Color(0xFFF59E0B)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                    isSelected
                        ? const Color(0xFF6366F1)
                        : isPending
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF334155),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sentences[index],
                    style: TextStyle(
                      color: isSelected || isPending ? Colors.white : Colors.white70,
                      fontWeight: isSelected || isPending
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.volume_up,
                      color: Color(0xFF818CF8),
                      size: 18,
                    ),
                  ),
                if (isPending && !isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.touch_app,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
