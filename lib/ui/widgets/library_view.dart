import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/document/saved_book.dart';
import '../app_theme.dart';
import 'vozlume_icon.dart';

class LibraryView extends StatelessWidget {
  final List<SavedBookRecord> books;
  final String importStatus;
  final String engineStatus;
  final String? errorMessage;
  final bool isProcessing;
  final bool searchMode;
  final String searchQuery;
  final VoidCallback onImport;
  final ValueChanged<SavedBookRecord> onOpenBook;
  final ValueChanged<SavedBookRecord> onDeleteBook;
  final ValueChanged<String> onSearchChanged;

  const LibraryView({
    super.key,
    required this.books,
    required this.importStatus,
    required this.engineStatus,
    required this.isProcessing,
    required this.onImport,
    required this.onOpenBook,
    required this.onDeleteBook,
    this.errorMessage,
    this.searchMode = false,
    this.searchQuery = '',
    this.onSearchChanged = _ignoreSearch,
  });

  static void _ignoreSearch(String _) {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final visibleBooks = normalizedQuery.isEmpty
        ? books
        : books
            .where(
              (book) =>
                  book.title.toLowerCase().contains(normalizedQuery) ||
                  book.author.toLowerCase().contains(normalizedQuery),
            )
            .toList(growable: false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          key: const Key('library-scroll-view'),
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _LibraryHeader(engineStatus: engineStatus),
            const SizedBox(height: AppSpacing.xl),
            if (searchMode) ...[
              TextField(
                key: const Key('library-search-field'),
                autofocus: true,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar na biblioteca',
                  hintText: 'Título ou autor',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else ...[
              _ImportCard(
                isProcessing: isProcessing,
                onImport: onImport,
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  importStatus,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statusMono.copyWith(
                    color: ext?.textWeak ?? theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (errorMessage != null) ...[
              _ErrorBanner(message: errorMessage!),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              searchMode ? 'Resultados' : 'Continuar lendo',
              style: theme.textTheme.titleMedium ?? AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (visibleBooks.isEmpty)
              _EmptyLibrary(searchMode: searchMode)
            else
              ...visibleBooks.map(
                (book) => SavedBookTile(
                  record: book,
                  onOpen: () => onOpenBook(book),
                  onDelete: () => _confirmDelete(context, book),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavedBookRecord book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover livro'),
        content: Text('Deseja remover "${book.title}" da biblioteca? O arquivo salvo e o progresso de leitura serão excluídos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteBook(book);
            },
            child: Text(
              'Remover',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final String engineStatus;

  const _LibraryHeader({required this.engineStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VozLumeIcon(size: 32),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VozLume', style: theme.textTheme.titleLarge ?? AppTextStyles.brandDisplay),
                Text(
                  'Leitor neural de EPUB',
                  style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Chip(
          avatar: Icon(
            Icons.graphic_eq,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          label: Text(engineStatus),
        ),
      ],
    );
  }
}

class _ImportCard extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onImport;

  const _ImportCard({required this.isProcessing, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Semantics(
      button: true,
      label: isProcessing ? 'Importando EPUB' : 'Importar EPUB',
      child: CustomPaint(
        painter: _DashedBorderPainter(color: ext?.textWeak ?? theme.colorScheme.outline),
        child: InkWell(
          key: const Key('import-epub-card'),
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: isProcessing ? null : onImport,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                if (isProcessing)
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.add_to_photos, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar EPUB',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'O arquivo permanece somente neste dispositivo.',
                        style: TextStyle(
                          color: ext?.textSoft ?? theme.colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: ext?.textWeak ?? theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 7.0;
    const gap = 5.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.md),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}

class _EmptyLibrary extends StatelessWidget {
  final bool searchMode;

  const _EmptyLibrary({required this.searchMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Container(
      key: const Key('empty-library-state'),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: ext?.card ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, color: ext?.textWeak ?? theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            searchMode
                ? 'Nenhum livro corresponde à busca.'
                : 'Sua biblioteca ainda está vazia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ext?.textSoft ?? theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('library-error-banner'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: .16),
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedBookTile extends StatelessWidget {
  final SavedBookRecord record;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const SavedBookTile({
    super.key,
    required this.record,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final hasCover = record.coverPath != null &&
        record.coverPath!.isNotEmpty &&
        File(record.coverPath!).existsSync();

    return Card(
      color: ext?.card ?? theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        key: Key('saved-book-${record.id}'),
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  width: 44,
                  height: 60,
                  alignment: Alignment.center,
                  color: ext?.cardElevated ?? theme.colorScheme.surfaceContainerHighest,
                  child: hasCover
                      ? Image.file(
                          File(record.coverPath!),
                          width: 44,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.auto_stories,
                              color: theme.colorScheme.primary,
                            );
                          },
                        )
                      : Icon(
                          Icons.auto_stories,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      record.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ext?.textSoft ?? theme.colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: record.progress,
                      minHeight: 2,
                      backgroundColor: theme.colorScheme.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ext?.grifo ?? theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${record.progressPercent}%',
                style: AppTextStyles.statusMono.copyWith(
                  color: ext?.textWeak ?? theme.colorScheme.onSurface,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções do livro',
                icon: Icon(Icons.more_vert, color: ext?.textWeak ?? theme.colorScheme.outline),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Remover da biblioteca'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
