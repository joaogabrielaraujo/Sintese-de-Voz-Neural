import 'dart:convert';

/// Modelo de Dados para Avaliação Auditiva Perceptual (Mean Opinion Score - MOS).
class MOSRating {
  final String id;
  final DateTime timestamp;
  final String sampleText;
  final int prosodyScore; // 1 a 5 (Fluidez e entonação)
  final int plnClarityScore; // 1 a 5 (Normalização de números, siglas, datas)
  final int audioQualityScore; // 1 a 5 (Ausência de ruídos ONNX)
  final int latencyScore; // 1 a 5 (Percepção de velocidade/resposta)
  final String? comments;

  MOSRating({
    required this.id,
    required this.timestamp,
    required this.sampleText,
    required this.prosodyScore,
    required this.plnClarityScore,
    required this.audioQualityScore,
    required this.latencyScore,
    this.comments,
  });

  /// Média geral dos critérios do MOS.
  double get averageScore =>
      (prosodyScore + plnClarityScore + audioQualityScore + latencyScore) / 4.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'sampleText': sampleText,
        'prosodyScore': prosodyScore,
        'plnClarityScore': plnClarityScore,
        'audioQualityScore': audioQualityScore,
        'latencyScore': latencyScore,
        'averageScore': averageScore,
        'comments': comments,
      };

  factory MOSRating.fromJson(Map<String, dynamic> json) => MOSRating(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sampleText: json['sampleText'] as String,
        prosodyScore: json['prosodyScore'] as int,
        plnClarityScore: json['plnClarityScore'] as int,
        audioQualityScore: json['audioQualityScore'] as int,
        latencyScore: json['latencyScore'] as int,
        comments: json['comments'] as String?,
      );

  String encodeJson() => jsonEncode(toJson());
}
