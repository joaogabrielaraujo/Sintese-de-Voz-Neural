import 'package:flutter/material.dart';
import '../../core/metrics/mos_rating_model.dart';

/// Modal para Coleta da Avaliação Perceptual da Voz Neural (Mean Opinion Score - MOS).
class MOSEvaluationDialog extends StatefulWidget {
  final String sampleText;
  final Function(MOSRating rating) onSubmitted;

  const MOSEvaluationDialog({
    super.key,
    required this.sampleText,
    required this.onSubmitted,
  });

  @override
  State<MOSEvaluationDialog> createState() => _MOSEvaluationDialogState();
}

class _MOSEvaluationDialogState extends State<MOSEvaluationDialog> {
  int _prosody = 5;
  int _plnClarity = 5;
  int _audioQuality = 5;
  int _latency = 5;
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Widget _buildStarRating({
    required String label,
    required String tooltip,
    required int rating,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Text(
              '$rating/5',
              style: const TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          tooltip,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              iconSize: 24,
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(),
              icon: Icon(
                starValue <= rating ? Icons.star : Icons.star_border,
                color: starValue <= rating ? const Color(0xFFF59E0B) : Colors.grey,
              ),
              onPressed: () => onChanged(starValue),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Row(
        children: [
          Icon(Icons.rate_review, color: Color(0xFF818CF8)),
          SizedBox(width: 8),
          Text(
            'Avaliação Auditiva (MOS)',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Amostra: "${widget.sampleText.length > 60 ? '${widget.sampleText.substring(0, 60)}...' : widget.sampleText}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStarRating(
                label: '1. Prosódia & Naturalidade',
                tooltip: 'Fluidez, entonação e ritmo da voz PT-BR.',
                rating: _prosody,
                onChanged: (val) => setState(() => _prosody = val),
              ),
              _buildStarRating(
                label: '2. Normalização PLN',
                tooltip: 'Pronúncia de números, siglas, ordenais e datas.',
                rating: _plnClarity,
                onChanged: (val) => setState(() => _plnClarity = val),
              ),
              _buildStarRating(
                label: '3. Qualidade do Áudio',
                tooltip: 'Clareza sonora e ausência de ruídos ONNX.',
                rating: _audioQuality,
                onChanged: (val) => setState(() => _audioQuality = val),
              ),
              _buildStarRating(
                label: '4. Velocidade / Latência',
                tooltip: 'Rapidez na geração e percepção de fluidez.',
                rating: _latency,
                onChanged: (val) => setState(() => _latency = val),
              ),
              TextField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Observações / Feedback (Opcional)',
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
          ),
          onPressed: () {
            final rating = MOSRating(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              timestamp: DateTime.now(),
              sampleText: widget.sampleText,
              prosodyScore: _prosody,
              plnClarityScore: _plnClarity,
              audioQualityScore: _audioQuality,
              latencyScore: _latency,
              comments: _commentsController.text.trim().isNotEmpty
                  ? _commentsController.text.trim()
                  : null,
            );
            widget.onSubmitted(rating);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar Avaliação', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
