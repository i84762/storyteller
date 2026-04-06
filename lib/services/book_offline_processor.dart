import 'dart:typed_data';
import '../models/offline_config.dart';
import '../providers/model_provider.dart';
import '../services/image_generation_service.dart';
import '../services/offline_image_cache_service.dart';
import '../services/page_cache_service.dart';
import '../services/pdf_service.dart';

/// Processes every page of a book through two phases:
///
///   Phase 1 — Text: AI-transforms each page and writes to [PageCacheService].
///   Phase 2 — Images (optional): generates an illustration per page via
///              Pollinations.ai HQ and writes to [OfflineImageCacheService].
///
/// Progress callback signature: onProgress(textDone, imageDone, total)
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
    required void Function(int textDone, int imageDone, int total) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    final pdf = PdfService();
    try {
      await pdf.loadFromPath(config.bookPath);
    } catch (e) {
      onError('Could not open PDF: $e');
      return;
    }

    final total = pdf.totalPages;

    // ── Phase 1: Text transformation ─────────────────────────────────────────
    for (int page = 0; page < total; page++) {
      if (_cancelled) break;

      final existing = await pageCache.get(
        config.bookPath, page, config.mode.name, null,
        config.aiTier, config.tone.name,
      );
      if (existing != null) {
        config.processedPages = page + 1;
        onProgress(page + 1, config.processedImages, total);
        continue;
      }

      try {
        final rawText = await pdf.getPageAsync(page);
        if (rawText.trim().isNotEmpty) {
          // Retry once on failure
          String? transformed;
          for (int attempt = 0; attempt < 2 && transformed == null; attempt++) {
            try {
              transformed = await modelProvider.transformPageForMode(
                rawText, config.mode, tone: config.tone,
              );
            } catch (_) {
              if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
            }
          }
          if (transformed != null && transformed.isNotEmpty && transformed != rawText) {
            await pageCache.put(
              config.bookPath, page, config.mode.name, null,
              config.aiTier, config.tone.name, transformed,
            );
          }
        }
      } catch (_) {
        // Continue — page will be processed on demand when read
      }

      config.processedPages = page + 1;
      onProgress(page + 1, config.processedImages, total);

      // ~4s between pages ≈ 15 req/min — stays within Gemini free tier RPM limit.
      if (!_cancelled) {
        await Future.delayed(const Duration(milliseconds: 4000));
      }
    }

    if (_cancelled) {
      pdf.dispose();
      return;
    }

    // ── Phase 2: Image generation (only if requested) ─────────────────────────
    if (config.includePictures) {
      for (int page = 0; page < total; page++) {
        if (_cancelled) break;

        // Skip if already on disk
        if (await OfflineImageCacheService.hasImage(config.bookPath, page)) {
          config.processedImages = page + 1;
          onProgress(config.processedPages, page + 1, total);
          continue;
        }

        try {
          final cachedText = await pageCache.get(
            config.bookPath, page, config.mode.name, null,
            config.aiTier, config.tone.name,
          );
          final rawText = await pdf.getPageAsync(page);
          final contextText = (cachedText?.isNotEmpty == true) ? cachedText! : rawText;

          if (contextText.trim().isNotEmpty) {
            // Step 1: generate visual prompt via text AI (retry once)
            String? imagePrompt;
            for (int attempt = 0; attempt < 2 && imagePrompt == null; attempt++) {
              try {
                imagePrompt = await modelProvider.generateImagePrompt(
                  contextText, config.mode, config.tone,
                );
              } catch (_) {
                if (attempt == 0) await Future.delayed(const Duration(seconds: 3));
              }
            }

            if (imagePrompt != null && imagePrompt.isNotEmpty) {
              // Step 2: generate image at HQ size (retry once)
              Uint8List? imageBytes;
              for (int attempt = 0; attempt < 2 && imageBytes == null; attempt++) {
                imageBytes = await ImageGenerationService.generatePollinationsHQ(imagePrompt);
                if (imageBytes == null && attempt == 0) {
                  await Future.delayed(const Duration(seconds: 5));
                }
              }

              if (imageBytes != null) {
                await OfflineImageCacheService.put(config.bookPath, page, imageBytes);
              }
            }
          }
        } catch (_) {
          // Non-fatal — image will generate on demand when page is read
        }

        config.processedImages = page + 1;
        onProgress(config.processedPages, page + 1, total);

        // Throttle: be polite to Pollinations.ai (1 request/sec)
        if (!_cancelled) {
          await Future.delayed(const Duration(milliseconds: 1200));
        }
      }
    }

    pdf.dispose();

    if (!_cancelled) {
      config.processedAt = DateTime.now();
      onComplete();
    }
  }
}
