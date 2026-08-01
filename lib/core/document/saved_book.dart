import 'dart:typed_data';

class SavedBookRecord {
  final String id;
  final String fileName;
  final String title;
  final String author;
  final String contentHash;
  final int totalChapters;
  final int chapterIndex;
  final int sentenceIndex;
  final int completedSentenceIndex;
  final double progress;
  final DateTime updatedAt;

  const SavedBookRecord({
    required this.id,
    required this.fileName,
    required this.title,
    required this.author,
    this.contentHash = '',
    required this.totalChapters,
    required this.chapterIndex,
    required this.sentenceIndex,
    this.completedSentenceIndex = -1,
    required this.progress,
    required this.updatedAt,
  });

  int get progressPercent => (progress.clamp(0.0, 1.0) * 100).round();

  SavedBookRecord copyWith({
    int? chapterIndex,
    int? sentenceIndex,
    int? completedSentenceIndex,
    double? progress,
    DateTime? updatedAt,
  }) {
    return SavedBookRecord(
      id: id,
      fileName: fileName,
      title: title,
      author: author,
      contentHash: contentHash,
      totalChapters: totalChapters,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      sentenceIndex: sentenceIndex ?? this.sentenceIndex,
      completedSentenceIndex:
          completedSentenceIndex ?? this.completedSentenceIndex,
      progress: (progress ?? this.progress).clamp(0.0, 1.0).toDouble(),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'fileName': fileName,
        'title': title,
        'author': author,
        'contentHash': contentHash,
        'totalChapters': totalChapters,
        'chapterIndex': chapterIndex,
        'sentenceIndex': sentenceIndex,
        'completedSentenceIndex': completedSentenceIndex,
        'progress': progress,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavedBookRecord.fromJson(Map<String, dynamic> json) {
    return SavedBookRecord(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String? ?? 'Livro sem título',
      author: json['author'] as String? ?? 'Autor desconhecido',
      contentHash: json['contentHash'] as String? ?? '',
      totalChapters: (json['totalChapters'] as num?)?.toInt() ?? 0,
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
      sentenceIndex: (json['sentenceIndex'] as num?)?.toInt() ?? 0,
      completedSentenceIndex:
          (json['completedSentenceIndex'] as num?)?.toInt() ?? -1,
      progress: ((json['progress'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SavedBookData {
  final SavedBookRecord record;
  final Uint8List bytes;

  const SavedBookData({required this.record, required this.bytes});
}
