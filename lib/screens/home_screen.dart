import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_record.dart';
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

    final gradientColors = isDark
        ? const [Color(0xFF100D16), Color(0xFF1A1528), Color(0xFF221D33)]
        : const [Color(0xFFF8F0E3), Color(0xFFF0DCC0), Color(0xFFEDD8B8)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StoryTeller',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.currentTier.displayName,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.tune,
                              color: cs.onSurface.withValues(alpha: 0.7)),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.workspace_premium,
                              color: Colors.amber),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/subscription'),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Expanded(
                child: books.isEmpty
                    ? _HeroSection(reader: reader)
                    : _RecentSection(
                        books: books.take(3).toList(),
                        hasMore: books.length > 3,
                        reader: reader,
                        onOpen: (rec) => _loadAndNavigate(context, reader, rec),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Open PDF',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () => _openPdf(context, reader),
                ),
              ),

              if (reader.hasPdf) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                      side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.25)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Continue Reading'),
                    onPressed: () => Navigator.pushNamed(context, '/reader'),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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
            onPressed: reader.clearError,
          ),
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

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final ReaderProvider reader;
  const _HeroSection({required this.reader});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.auto_stories, color: cs.primary, size: 72),
          ),
          const SizedBox(height: 32),
          Text(
            'Your AI Reading\nCompanion',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Load a PDF and let AI read it to you.\nAsk questions. Navigate by voice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent books (home — max 3) ───────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  final List<BookRecord> books;
  final bool hasMore;
  final ReaderProvider reader;
  final void Function(BookRecord) onOpen;

  const _RecentSection({
    required this.books,
    required this.hasMore,
    required this.reader,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.history,
                  color: cs.onSurface.withValues(alpha: 0.5), size: 18),
              const SizedBox(width: 8),
              Text(
                'Recent',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (hasMore)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/library'),
                  child: Text('See all →',
                      style: TextStyle(color: cs.primary, fontSize: 13)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: books.length,
            itemBuilder: (ctx, i) =>
                BookCard(record: books[i], reader: reader, onOpen: onOpen),
          ),
        ),
      ],
    );
  }
}

// ── Book card (shared with LibraryScreen) ─────────────────────────────────────

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
    final timeAgo = _timeAgo(record.lastOpened);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onOpen(record),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: cs.outline.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(
                          record.isPinned ? Colors.amber : cs.primary),
                    ),
                  ),
                  Icon(
                    record.isPinned ? Icons.push_pin : Icons.menu_book,
                    color: record.isPinned
                        ? Colors.amber
                        : cs.onSurface.withValues(alpha: 0.6),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(width: 14),
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
                          fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Page ${record.lastPage + 1} of ${record.totalPages}  ·  $timeAgo',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: cs.outline.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      record.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: record.isPinned
                          ? Colors.amber
                          : cs.onSurface.withValues(alpha: 0.35),
                    ),
                    tooltip: record.isPinned ? 'Unpin' : 'Pin',
                    onPressed: () => reader.togglePin(record.path),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.28)),
                    tooltip: 'Remove from history',
                    onPressed: () => _confirmRemove(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
