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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'StoryTeller',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.currentTier.displayName,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white70),
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

              // Body
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

              // Open PDF button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
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
                      side: const BorderSide(color: Colors.white30),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.menu_book, color: Colors.white70),
                    label: const Text('Continue Reading',
                        style: TextStyle(color: Colors.white70)),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/reader'),
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

// ── Hero section (no books yet) ───────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final ReaderProvider reader;
  const _HeroSection({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.deepPurple.shade900,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withAlpha(128),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories,
                color: Colors.white, size: 72),
          ),
          const SizedBox(height: 32),
          const Text(
            'Your AI Reading\nCompanion',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Load a PDF and let AI read it to you.\nAsk questions. Navigate by voice.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Recent',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (hasMore)
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/library'),
                  child: const Text(
                    'See all →',
                    style: TextStyle(
                        color: Colors.deepPurpleAccent, fontSize: 13),
                  ),
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
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                          record.isPinned
                              ? Colors.amber
                              : Colors.deepPurple.shade300),
                    ),
                  ),
                  Icon(
                    record.isPinned ? Icons.push_pin : Icons.menu_book,
                    color: record.isPinned ? Colors.amber : Colors.white70,
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Page ${record.lastPage + 1} of ${record.totalPages}  ·  $timeAgo',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(
                            Colors.deepPurple.shade300),
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
                      color:
                          record.isPinned ? Colors.amber : Colors.white38,
                    ),
                    tooltip: record.isPinned ? 'Unpin' : 'Pin',
                    onPressed: () => reader.togglePin(record.path),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white30),
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
        content:
            Text('"${record.title}" will be removed from recent books.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              reader.removeBook(record.path);
              Navigator.pop(context);
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.red)),
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
