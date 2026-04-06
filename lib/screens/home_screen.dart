import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_record.dart';
import '../models/listening_mode.dart';
import '../models/offline_config.dart';
import '../models/reading_tone.dart';
import '../models/subscription_tier.dart';
import '../providers/reader_provider.dart';
import '../providers/model_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final model = context.watch<ModelProvider>();
    final books = reader.recentBooks;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Most-recent book (hero candidate)
    final heroBook = books.isNotEmpty ? books.first : null;
    // Remaining recent books (after the hero)
    final shelfBooks = books.length > 1 ? books.skip(1).take(2).toList() : <BookRecord>[];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF100D16), const Color(0xFF1A1528)]
                : [const Color(0xFFF8F0E3), const Color(0xFFEDD8B8)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'StoryTeller',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tier pill
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/subscription'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            model.currentTier.displayName,
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.tune,
                            color: cs.onSurface.withValues(alpha: 0.6)),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/settings'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Hero card (continue listening) ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: heroBook != null
                      ? _HeroBookCard(
                          record: heroBook,
                          reader: reader,
                          onOpen: (r) =>
                              _loadAndNavigate(context, reader, r),
                        )
                      : _WelcomeHero(reader: reader),
                ),
              ),

              // ── Recent shelf ──────────────────────────────────────────────
              if (shelfBooks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'RECENT',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/library'),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          child: Text('All books',
                              style: TextStyle(
                                  color: cs.primary, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BookCard(
                        record: shelfBooks[i],
                        reader: reader,
                        onOpen: (r) => _loadAndNavigate(ctx, reader, r),
                      ),
                    ),
                    childCount: shelfBooks.length,
                  ),
                ),
              ],

              // ── Offline Books ─────────────────────────────────────────────
              if (reader.offlineBooks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 10),
                    child: Text(
                      'OFFLINE READY',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final cfg = reader.offlineBooks[i];
                      final rec = reader.recentBooks.firstWhere(
                        (b) => b.path == cfg.bookPath,
                        orElse: () => BookRecord(
                          path: cfg.bookPath,
                          title: cfg.bookTitle,
                          lastPage: 0,
                          totalPages: cfg.totalPages,
                          lastOpened:
                              cfg.processedAt ?? DateTime.now(),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: _OfflineBookTile(
                          config: cfg,
                          onTap: () =>
                              _loadAndNavigate(ctx, reader, rec),
                        ),
                      );
                    },
                    childCount: reader.offlineBooks.length,
                  ),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // ── FAB: Open PDF ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPdf(context, reader),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.upload_file),
        label: const Text('Open PDF',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Future<void> _openPdf(BuildContext context, ReaderProvider reader) async {
    final success = await reader.pickAndLoadPdf();
    if (!context.mounted) return;
    if (success) {
      Navigator.pushNamed(context, '/reader');
    } else if (reader.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reader.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: reader.clearError),
        ),
      );
      reader.clearError();
    }
  }

  Future<void> _loadAndNavigate(
      BuildContext context, ReaderProvider reader, BookRecord rec) async {
    final success = await reader.loadFromRecord(rec);
    if (!context.mounted) return;
    if (success) {
      Navigator.pushNamed(context, '/reader');
    } else if (reader.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reader.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      reader.clearError();
    }
  }
}

// ── Offline book tile ─────────────────────────────────────────────────────────

class _OfflineBookTile extends StatelessWidget {
  final OfflineConfig config;
  final VoidCallback onTap;

  const _OfflineBookTile({required this.config, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isProcessing = config.isProcessing;
    final isImagePhase =
        isProcessing && config.includePictures && config.processedPages >= config.totalPages;
    final progressColor = isImagePhase ? Colors.deepOrange : cs.primary;

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Opacity(
        opacity: isProcessing ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isProcessing ? Icons.hourglass_top : Icons.offline_pin,
                    color: isProcessing ? cs.primary : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                config.bookTitle,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (config.includePictures) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '📸 Pictorial',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${config.mode.displayName} · ${config.tone.emoji} ${config.tone.displayName}',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        if (config.isComplete && config.includePictures)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${config.totalPages} pages · ${config.processedImages} illustrations',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (!config.isComplete && !isProcessing)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: LinearProgressIndicator(
                              value: config.progress,
                              backgroundColor:
                                  cs.outline.withValues(alpha: 0.1),
                              color: cs.primary,
                              minHeight: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isProcessing) ...[
                    const SizedBox(width: 8),
                    Text(
                      isImagePhase ? '🎨' : '⚙️',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ] else if (config.processedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _fmtDate(config.processedAt!),
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              if (isProcessing) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  backgroundColor: cs.outline.withValues(alpha: 0.1),
                  color: progressColor,
                  minHeight: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  config.statusLabel,
                  style: TextStyle(
                    color: isImagePhase
                        ? Colors.deepOrange
                        : cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Welcome hero (no books yet) ───────────────────────────────────────────────

class _WelcomeHero extends StatelessWidget {
  final ReaderProvider reader;
  const _WelcomeHero({required this.reader});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
            ),
            child: Icon(Icons.auto_stories, color: cs.primary, size: 44),
          ),
          const SizedBox(height: 20),
          Text(
            'Your AI Reading Companion',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load any PDF and listen in any language.\nAI-powered summaries, study mode, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero book card (continue listening) ──────────────────────────────────────

class _HeroBookCard extends StatelessWidget {
  final BookRecord record;
  final ReaderProvider reader;
  final void Function(BookRecord) onOpen;

  const _HeroBookCard({
    required this.record,
    required this.reader,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = record.progress;
    final pct = (progress * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [cs.primaryContainer, cs.surfaceContainerHighest]
              : [cs.primaryContainer.withValues(alpha: 0.8),
                 cs.primaryContainer.withValues(alpha: 0.3)],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onOpen(record),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book,
                          color: cs.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONTINUE LISTENING',
                            style: TextStyle(
                              color: cs.primary.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            record.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      'Page ${record.lastPage + 1} of ${record.totalPages}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct% complete',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Play button row
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text('Resume',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        onPressed: () => onOpen(record),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PinButton(record: record, reader: reader),
                    const SizedBox(width: 4),
                    _RemoveButton(record: record, reader: reader),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final BookRecord record;
  final ReaderProvider reader;
  const _PinButton({required this.record, required this.reader});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(
        record.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        size: 20,
        color: record.isPinned
            ? Colors.amber
            : cs.onSurface.withValues(alpha: 0.4),
      ),
      tooltip: record.isPinned ? 'Unpin' : 'Pin',
      onPressed: () => reader.togglePin(record.path),
      style: IconButton.styleFrom(
        backgroundColor: cs.onSurface.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final BookRecord record;
  final ReaderProvider reader;
  const _RemoveButton({required this.record, required this.reader});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.close,
          size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
      tooltip: 'Remove',
      onPressed: () => _confirmRemove(context),
      style: IconButton.styleFrom(
        backgroundColor: cs.onSurface.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from history?'),
        content: Text('"${record.title}" will be removed from recent books.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              reader.removeBook(record.path);
              Navigator.pop(context);
            },
            child: Text('Remove',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── Compact book card (recent shelf) ─────────────────────────────────────────

class BookCard extends StatelessWidget {
  final BookRecord record;
  final ReaderProvider reader;
  final void Function(BookRecord) onOpen;

  const BookCard({
    super.key,
    required this.record,
    required this.reader,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = record.progress;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpen(record),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: cs.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(
                          record.isPinned ? Colors.amber : cs.primary),
                    ),
                  ),
                  Icon(
                    record.isPinned ? Icons.push_pin : Icons.menu_book,
                    color: record.isPinned
                        ? Colors.amber
                        : cs.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'p.${record.lastPage + 1}/${record.totalPages}  ·  ${_timeAgo(record.lastOpened)}',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
