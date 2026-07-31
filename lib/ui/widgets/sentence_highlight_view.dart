import 'package:flutter/material.dart';

/// Componente visual para exibir as sentenças do texto com destaque em tempo real.
class SentenceHighlightView extends StatelessWidget {
  final List<String> sentences;
  final int activeIndex;
  final ValueChanged<int>? onSentenceTap;

  const SentenceHighlightView({
    super.key,
    required this.sentences,
    required this.activeIndex,
    this.onSentenceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sentences.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma sentença carregada para síntese.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: sentences.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final isSelected = index == activeIndex;
        return GestureDetector(
          onTap: () => onSentenceTap?.call(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1).withOpacity(0.2)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF818CF8) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
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
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
