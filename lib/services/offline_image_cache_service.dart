import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Persists AI-generated page illustrations to disk for offline use.
///
/// Storage layout:
///   {appDocDir}/storyteller_images/{bookHash}/page_{4-digit-index}.jpg
///
/// bookHash = filesystem-safe identifier derived from bookPath
///   (replace non-alphanumeric chars with '_', take last 40 chars)
class OfflineImageCacheService {
  static Future<Directory> _bookDir(String bookPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final hash = _hashPath(bookPath);
    final dir = Directory('${appDir.path}/storyteller_images/$hash');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _hashPath(String path) {
    final sanitised = path.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return sanitised.length > 40
        ? sanitised.substring(sanitised.length - 40)
        : sanitised;
  }

  static String _fileName(int pageIndex) =>
      'page_${pageIndex.toString().padLeft(4, '0')}.jpg';

  /// Returns cached image bytes for [pageIndex], or null if not cached.
  static Future<Uint8List?> get(String bookPath, int pageIndex) async {
    try {
      final dir = await _bookDir(bookPath);
      final file = File('${dir.path}/${_fileName(pageIndex)}');
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Persists [bytes] for [pageIndex].
  static Future<void> put(
      String bookPath, int pageIndex, Uint8List bytes) async {
    try {
      final dir = await _bookDir(bookPath);
      final file = File('${dir.path}/${_fileName(pageIndex)}');
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  /// Returns true if an image exists for [pageIndex].
  static Future<bool> hasImage(String bookPath, int pageIndex) async {
    try {
      final dir = await _bookDir(bookPath);
      return File('${dir.path}/${_fileName(pageIndex)}').exists();
    } catch (_) {
      return false;
    }
  }

  /// Counts how many page images are stored for this book.
  static Future<int> imageCount(String bookPath) async {
    try {
      final dir = await _bookDir(bookPath);
      if (!await dir.exists()) return 0;
      return dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Total bytes used by images for this book.
  static Future<int> totalSizeBytes(String bookPath) async {
    try {
      final dir = await _bookDir(bookPath);
      if (!await dir.exists()) return 0;
      int total = 0;
      for (final f in dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))) {
        total += await f.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes all images for this book.
  static Future<void> deleteForBook(String bookPath) async {
    try {
      final dir = await _bookDir(bookPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
