import 'package:flutter/material.dart';

import '../../core/document/saved_book.dart';
import '../app_theme.dart';

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
        constraints: const BoxConstraints(maxWidth: 920),
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
                  style: AppTextStyles.metric,
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
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (visibleBooks.isEmpty)
              _EmptyLibrary(searchMode: searchMode)
            else
              ...visibleBooks.map(
                (book) => SavedBookTile(
                  record: book,
                  onOpen: () => onOpenBook(book),
                  onDelete: () => onDeleteBook(book),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final String engineStatus;

  const _LibraryHeader({required this.engineStatus});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VozLume', style: AppTextStyles.sectionTitle),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Leitor neural de EPUB',
              style: TextStyle(color: AppColors.paperDim),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            const Chip(
              avatar: Icon(Icons.offline_bolt, color: AppColors.teal, size: 16),
              label: Text('OFFLINE'),
            ),
            Chip(
              avatar: const Icon(
                Icons.graphic_eq,
                color: AppColors.amber,
                size: 16,
              ),
              label: Text(engineStatus),
            ),
          ],
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
    return Semantics(
      button: true,
      label: isProcessing ? 'Importando EPUB' : 'Importar EPUB',
      child: CustomPaint(
        painter: _DashedBorderPainter(),
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
                  const Icon(Icons.add_to_photos, color: AppColors.amber),
                const SizedBox(width: AppSpacing.lg),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar EPUB',
                        style: TextStyle(
                          color: AppColors.paper,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'O arquivo permanece somente neste dispositivo.',
                        style:
                            TextStyle(color: AppColors.paperDim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.paperFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dash = 7.0;
    const gap = 5.0;
    final paint = Paint()
      ..color = AppColors.paperFaint
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyLibrary extends StatelessWidget {
  final bool searchMode;

  const _EmptyLibrary({required this.searchMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('empty-library-state'),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined, color: AppColors.paperFaint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            searchMode
                ? 'Nenhum livro corresponde à busca.'
                : 'Sua biblioteca ainda está vazia.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.paperDim),
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
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('library-error-banner'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: .16),
          border: Border.all(color: AppColors.coral),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child:
                  Text(message, style: const TextStyle(color: AppColors.paper)),
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
    return Card(
      color: AppColors.ink2,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        key: Key('saved-book-${record.id}'),
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.auto_stories, color: AppColors.amber),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      record.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.paperDim, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: record.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.line,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.amber),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${record.progressPercent}%', style: AppTextStyles.metric),
              PopupMenuButton<String>(
                tooltip: 'Opções do livro',
                icon: const Icon(Icons.more_vert, color: AppColors.paperFaint),
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
