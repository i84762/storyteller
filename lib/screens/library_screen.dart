import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_record.dart';
import '../providers/reader_provider.dart';
import 'home_screen.dart' show BookCard;

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final books = reader.recentBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        centerTitle: true,
        actions: [
          if (books.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Open new PDF',
              onPressed: () => _openPdf(context, reader),
            ),
        ],
      ),
      body: books.isEmpty
          ? const _EmptyLibrary()
          : Column(
              children: [
                // Stats row
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.menu_book,
                        label: '${books.length} book${books.length == 1 ? '' : 's'}',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.push_pin,
                        label: '${books.where((b) => b.isPinned).length} pinned',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: books.length,
                    itemBuilder: (ctx, i) => BookCard(
                      record: books[i],
                      reader: reader,
                      onOpen: (rec) => _loadAndNavigate(ctx, reader, rec),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openPdf(BuildContext context, ReaderProvider reader) async {
    final success = await reader.pickAndLoadPdf();
    if (!context.mounted) return;
    if (success) Navigator.pushReplacementNamed(context, '/reader');
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 12)),
      ],
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books_outlined,
              size: 72, color: Colors.brown),
          const SizedBox(height: 20),
          const Text('No books yet',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Open a PDF to start listening',
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}
