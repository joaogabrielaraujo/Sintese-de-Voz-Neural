import 'package:flutter/foundation.dart';

/// Modelo de dados imutável representando uma sentença fatiada para a síntese neural.
///
/// Armazena o texto limpo, seu índice sequencial no capítulo e metadados para
/// sincronização visual na interface do leitor de livros (UI).
@immutable
class TextSentence {
  /// Índice sequencial da sentença no documento (0-indexed).
  final int index;

  /// Conteúdo textual limpo da sentença.
  final String text;

  /// Indica se esta sentença finaliza um parágrafo no texto original.
  final bool isParagraphEnd;

  /// Construtor imutável com validações.
  const TextSentence({
    required this.index,
    required this.text,
    this.isParagraphEnd = false,
  }) : assert(index >= 0, 'O índice da sentença deve ser não-negativo');

  /// Quantidade de caracteres contidos na sentença.
  int get characterCount => text.length;

  /// Quantidade aproximada de palavras.
  int get wordCount => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Estima a duração da fala para esta sentença em segundos (média de 14 caracteres por segundo em PT-BR).
  double get estimatedDurationSeconds {
    if (characterCount == 0) return 0.0;
    return (characterCount / 14.0).clamp(0.5, 60.0);
  }

  /// Retorna uma cópia modificada do objeto.
  TextSentence copyWith({
    int? index,
    String? text,
    bool? isParagraphEnd,
  }) {
    return TextSentence(
      index: index ?? this.index,
      text: text ?? this.text,
      isParagraphEnd: isParagraphEnd ?? this.isParagraphEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSentence &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          text == other.text &&
          isParagraphEnd == other.isParagraphEnd;

  @override
  int get hashCode => index.hashCode ^ text.hashCode ^ isParagraphEnd.hashCode;

  @override
  String toString() {
    return 'TextSentence(#$index, chars: $characterCount, endPara: $isParagraphEnd, text: "$text")';
  }
}
