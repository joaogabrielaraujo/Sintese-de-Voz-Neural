import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/audio/audio_player_service_interface.dart';
import '../../core/document/epub_model.dart';
import '../../core/text/sentence_model.dart';
import '../app_theme.dart';
import 'audio_player_control_bar.dart';
import 'reader_document_view.dart';

class ReaderPage extends StatelessWidget {
  final EpubBook book;
  final EpubChapter chapter;
  final List<TextSentence> sentences;
  final int activeIndex;
  final int? pendingIndex;
  final bool isProcessing;
  final String synthesisStatus;
  final double? rtf;
  final IAudioPlayerService playerService;
  final TTSAudioState audioState;
  final Duration currentPosition;
  final Duration totalDuration;
  final double currentSpeed;
  final VoidCallback onBack;
  final ValueChanged<EpubChapter> onChapterChanged;
  final ValueChanged<int> onSentenceSelected;
  final VoidCallback onCancelSelection;
  final VoidCallback onConfirmSelection;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onOpenMos;

  const ReaderPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.sentences,
    required this.activeIndex,
    required this.isProcessing,
    required this.synthesisStatus,
    required this.playerService,
    required this.audioState,
    required this.currentPosition,
    required this.totalDuration,
    required this.currentSpeed,
    required this.onBack,
    required this.onChapterChanged,
    required this.onSentenceSelected,
    required this.onCancelSelection,
    required this.onConfirmSelection,
    required this.onPlayPause,
    required this.onStop,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onOpenMos,
    this.pendingIndex,
    this.rtf,
  });

  void _selectRelative(int delta) {
    if (sentences.isEmpty) return;
    final origin = pendingIndex ?? activeIndex;
    final target = (origin + delta).clamp(0, sentences.length - 1).toInt();
    onSentenceSelected(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): onPlayPause,
        const SingleActivator(LogicalKeyboardKey.escape):
            pendingIndex == null ? onBack : onCancelSelection,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _selectRelative(-1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _selectRelative(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _selectRelative(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _selectRelative(1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar para a biblioteca',
              onPressed: onBack,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Spectral',
                    fontFamilyFallback: const ['Georgia', 'serif'],
                    color: ext?.textSoft ?? theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.wide;
              final reading = _ReadingPane(
                book: book,
                chapter: chapter,
                sentences: sentences,
                activeIndex: activeIndex,
                pendingIndex: pendingIndex,
                isProcessing: isProcessing,
                onChapterChanged: onChapterChanged,
                onSentenceSelected: onSentenceSelected,
                onCancelSelection: onCancelSelection,
                onConfirmSelection: onConfirmSelection,
              );
              final player = _PlayerPane(
                compact: !wide,
                playerService: playerService,
                audioState: audioState,
                currentPosition: currentPosition,
                totalDuration: totalDuration,
                currentSpeed: currentSpeed,
                activeSentence: sentences.isEmpty
                    ? 0
                    : activeIndex.clamp(0, sentences.length - 1).toInt() + 1,
                sentenceCount: sentences.length,
                synthesisStatus: synthesisStatus,
                rtf: rtf,
                onPlayPause: onPlayPause,
                onStop: onStop,
                onSeek: onSeek,
                onSpeedChanged: onSpeedChanged,
                onOpenMos: onOpenMos,
              );

              if (wide) {
                return Row(
                  key: const Key('wide-reader-layout'),
                  children: [
                    Expanded(child: reading),
                    VerticalDivider(width: 1, color: theme.colorScheme.outline),
                    SizedBox(width: 370, child: player),
                  ],
                );
              }
              return Column(
                key: const Key('compact-reader-layout'),
                children: [
                  Expanded(child: reading),
                  player,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadingPane extends StatelessWidget {
  final EpubBook book;
  final EpubChapter chapter;
  final List<TextSentence> sentences;
  final int activeIndex;
  final int? pendingIndex;
  final bool isProcessing;
  final ValueChanged<EpubChapter> onChapterChanged;
  final ValueChanged<int> onSentenceSelected;
  final VoidCallback onCancelSelection;
  final VoidCallback onConfirmSelection;

  const _ReadingPane({
    required this.book,
    required this.chapter,
    required this.sentences,
    required this.activeIndex,
    required this.pendingIndex,
    required this.isProcessing,
    required this.onChapterChanged,
    required this.onSentenceSelected,
    required this.onCancelSelection,
    required this.onConfirmSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<EpubChapter>(
                      key: const Key('chapter-selector'),
                      value: chapter,
                      isExpanded: true,
                      dropdownColor: ext?.card ?? theme.colorScheme.surface,
                      items: book.chapters
                          .map(
                            (item) => DropdownMenuItem<EpubChapter>(
                              value: item,
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontFamily: 'Spectral',
                                  fontFamilyFallback: ['Georgia', 'serif'],
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (selected) {
                        if (selected != null) onChapterChanged(selected);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '${chapter.wordCount} palavras',
                    style: AppTextStyles.statusMono.copyWith(
                      color: ext?.textWeak ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReaderDocumentView(
                sentences: sentences,
                contentBlocks: chapter.contentBlocks,
                activeIndex: activeIndex,
                pendingIndex: pendingIndex,
                onSentenceTap: onSentenceSelected,
              ),
            ),
            if (pendingIndex != null)
              Container(
                key: const Key('reader-selection-confirmation'),
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: ext?.card ?? theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Text('Retomar da frase ${pendingIndex! + 1}?'),
                    OutlinedButton(
                      onPressed: onCancelSelection,
                      child: const Text('Cancelar'),
                    ),
                    FilledButton.icon(
                      onPressed: isProcessing ? null : onConfirmSelection,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerPane extends StatelessWidget {
  final bool compact;
  final IAudioPlayerService playerService;
  final TTSAudioState audioState;
  final Duration currentPosition;
  final Duration totalDuration;
  final double currentSpeed;
  final int activeSentence;
  final int sentenceCount;
  final String synthesisStatus;
  final double? rtf;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onOpenMos;

  const _PlayerPane({
    required this.compact,
    required this.playerService,
    required this.audioState,
    required this.currentPosition,
    required this.totalDuration,
    required this.currentSpeed,
    required this.activeSentence,
    required this.sentenceCount,
    required this.synthesisStatus,
    required this.rtf,
    required this.onPlayPause,
    required this.onStop,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onOpenMos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!compact) const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      synthesisStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statusMono.copyWith(
                        color: ext?.moss ?? theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Text(
                  'Frase $activeSentence/$sentenceCount',
                  style: AppTextStyles.statusMono.copyWith(
                    color: ext?.textWeak ?? theme.colorScheme.onSurface,
                  ),
                ),
                if (rtf != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'RTF ${rtf!.toStringAsFixed(3)}',
                    style: AppTextStyles.statusMono.copyWith(
                      color: ext?.grifo ?? theme.colorScheme.primary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'RTF —',
                    style: AppTextStyles.statusMono.copyWith(
                      color: ext?.textWeak ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AudioPlayerControlBar(
            playerService: playerService,
            currentState: audioState,
            currentPosition: currentPosition,
            totalDuration: totalDuration,
            currentSpeed: currentSpeed,
            onPlayPausePressed: onPlayPause,
            onStopPressed: onStop,
            onSeekChanged: onSeek,
            onSpeedChanged: onSpeedChanged,
            onOpenMOSDialog: onOpenMos,
          ),
        ],
      ),
    );
  }
}
