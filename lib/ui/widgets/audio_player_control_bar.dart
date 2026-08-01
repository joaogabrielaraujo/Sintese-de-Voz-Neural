import 'package:flutter/material.dart';
import '../../core/audio/audio_player_service_interface.dart';

/// Barra de Controles do Player de Áudio da Síntese Neural.
class AudioPlayerControlBar extends StatelessWidget {
  final IAudioPlayerService playerService;
  final TTSAudioState currentState;
  final Duration currentPosition;
  final Duration totalDuration;
  final double currentSpeed;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onStopPressed;
  final ValueChanged<Duration> onSeekChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onOpenMOSDialog;

  const AudioPlayerControlBar({
    super.key,
    required this.playerService,
    required this.currentState,
    required this.currentPosition,
    required this.totalDuration,
    required this.currentSpeed,
    required this.onPlayPausePressed,
    required this.onStopPressed,
    required this.onSeekChanged,
    required this.onSpeedChanged,
    required this.onOpenMOSDialog,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = currentState == TTSAudioState.playing;
    final maxMs = totalDuration.inMilliseconds > 0
        ? totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final currentMs = currentPosition.inMilliseconds
        .clamp(0, totalDuration.inMilliseconds)
        .toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider de Progresso e Tempo
          Row(
            children: [
              Text(
                _formatDuration(currentPosition),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6366F1),
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: const Color(0xFF818CF8),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: currentMs,
                    min: 0.0,
                    max: maxMs,
                    onChanged: (value) {
                      onSeekChanged(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Seletor de Velocidade
              DropdownButton<double>(
                value: currentSpeed,
                dropdownColor: const Color(0xFF1E293B),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                  DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                  DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                  DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                onChanged: (val) {
                  if (val != null) onSpeedChanged(val);
                },
              ),

              // Controles Centrais Play/Pause/Stop
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.white70),
                    onPressed: onStopPressed,
                    tooltip: 'Parar Áudio',
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    backgroundColor: const Color(0xFF6366F1),
                    onPressed: onPlayPausePressed,
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Botão de Avaliação MOS
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                label: const Text(
                  'Avaliar MOS',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: onOpenMOSDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
