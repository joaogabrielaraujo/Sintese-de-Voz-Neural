import 'package:flutter/material.dart';

import '../../core/audio/audio_player_service_interface.dart';
import '../app_theme.dart';

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
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final isPlaying = currentState == TTSAudioState.playing;
    final maxMs = totalDuration.inMilliseconds > 0
        ? totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final currentMs = currentPosition.inMilliseconds
        .clamp(0, totalDuration.inMilliseconds)
        .toDouble();

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('audio-player-control-bar'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: ext?.card ?? theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _formatDuration(currentPosition),
                  style: AppTextStyles.statusMono.copyWith(
                    color: ext?.textWeak ?? theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.outline,
                      thumbColor: theme.colorScheme.primary,
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: currentMs,
                      min: 0,
                      max: maxMs,
                      onChanged: (value) => onSeekChanged(
                        Duration(milliseconds: value.toInt()),
                      ),
                    ),
                  ),
                ),
                Text(
                  _formatDuration(totalDuration),
                  style: AppTextStyles.statusMono.copyWith(
                    color: ext?.textWeak ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final speedSelector = DropdownButton<double>(
                  key: const Key('playback-speed-selector'),
                  value: currentSpeed,
                  dropdownColor: ext?.card ?? theme.colorScheme.surface,
                  underline: const SizedBox(),
                  style: AppTextStyles.statusMono.copyWith(
                    color: ext?.textSoft ?? theme.colorScheme.onSurface,
                  ),
                  items: const [
                    DropdownMenuItem(value: .75, child: Text('0.75x')),
                    DropdownMenuItem(value: 1, child: Text('1.0x')),
                    DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2, child: Text('2.0x')),
                  ],
                  onChanged: (value) {
                    if (value != null) onSpeedChanged(value);
                  },
                );
                final playbackControls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.stop, color: ext?.textSoft ?? theme.colorScheme.onSurface),
                      onPressed: onStopPressed,
                      tooltip: 'Parar áudio',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FloatingActionButton.small(
                      heroTag: null,
                      backgroundColor: theme.colorScheme.primary,
                      onPressed: onPlayPausePressed,
                      tooltip: isPlaying ? 'Pausar áudio' : 'Reproduzir áudio',
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                );
                final mosButton = ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ext?.cardElevated ?? theme.colorScheme.surfaceContainerHighest,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  icon: Icon(Icons.star, color: ext?.grifo ?? theme.colorScheme.primary, size: 18),
                  label: Text(
                    compact ? 'MOS' : 'Avaliar MOS',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: onOpenMOSDialog,
                );

                if (compact) {
                  return Wrap(
                    key: const Key('compact-player-controls'),
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [speedSelector, playbackControls, mosButton],
                  );
                }
                return Row(
                  key: const Key('wide-player-controls'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [speedSelector, playbackControls, mosButton],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
