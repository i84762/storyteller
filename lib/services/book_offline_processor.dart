import '../models/offline_config.dart';
import '../providers/model_provider.dart';
import '../services/page_cache_service.dart';
import '../services/pdf_service.dart';

/// Processes every page of a book through AI and stores results in
/// [PageCacheService] so the book can be read offline without live AI calls.
class BookOfflineProcessor {
  final OfflineConfig config;
  final ModelProvider modelProvider;
  final PageCacheService pageCache;

  bool _cancelled = false;

  BookOfflineProcessor({
    required this.config,
    required this.modelProvider,
    required this.pageCache,
  });

  void cancel() => _cancelled = true;

  Future<void> process({
    required void Function(int done, int total) onProgress,
    required void Function() onComplete,
  }) async {
    // Open the PDF independently (separate instance from the reader).
    final pdf = PdfService();
    await pdf.loadFromPath(config.bookPath);
    final total = pdf.totalPages;

    for (int page = 0; page < total; page++) {
      if (_cancelled) break;

      // Skip pages already in the persistent cache.
      final existing = await pageCache.get(
        config.bookPath,
        page,
        config.mode.name,
        null,
        config.aiTier,
        config.tone.name,
      );
      if (existing != null) {
        config.processedPages = page + 1;
        onProgress(page + 1, total);
        continue;
      }

      try {
        final rawText = await pdf.getPageAsync(page);
        if (rawText.trim().isNotEmpty) {
          final transformed = await modelProvider.transformPageForMode(
            rawText,
            config.mode,
            tone: config.tone,
          );
          if (transformed != null &&
              transformed.isNotEmpty &&
              transformed != rawText) {
            await pageCache.put(
              config.bookPath,
              page,
              config.mode.name,
              null,
              config.aiTier,
              config.tone.name,
              transformed,
            );
          }
        }
      } catch (_) {
        // Continue on error — page will be processed on demand when read.
      }

      config.processedPages = page + 1;
      onProgress(page + 1, total);
    }

    pdf.dispose();

    if (!_cancelled) {
      config.processedAt = DateTime.now();
      onComplete();
    }
  }
}
