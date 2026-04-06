import 'dart:io';
import 'dart:isolate';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  String? _filePath;
  List<int>? _bytes;
  int _totalPages = 0;

  // LRU page-text cache — keeps at most [_maxCacheSize] pages in memory.
  final _pageCache = <int, String>{};
  static const int _maxCacheSize = 5;

  int get totalPages => _totalPages;

  /// Opens the PDF just long enough to count pages; no text is extracted yet.
  Future<void> loadFromPath(String filePath) async {
    _filePath = filePath;
    _bytes = null;
    _pageCache.clear();
    _totalPages = await Isolate.run(() {
      final bytes = File(filePath).readAsBytesSync();
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    });
  }

  /// Same as [loadFromPath] but sources bytes already in memory.
  Future<void> loadFromBytes(List<int> bytes) async {
    _bytes = bytes;
    _filePath = null;
    _pageCache.clear();
    _totalPages = await Isolate.run(() {
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    });
  }

  /// Returns the text for [index], loading it on demand if not yet cached.
  /// The isolate reads + extracts only that single page, then disposes everything.
  Future<String> getPageAsync(int index) async {
    if (index < 0 || index >= _totalPages) return '';
    if (_pageCache.containsKey(index)) return _pageCache[index]!;

    final filePath = _filePath;
    final bytes = _bytes;

    final text = await Isolate.run(() {
      final List<int> data;
      if (filePath != null) {
        data = File(filePath).readAsBytesSync();
      } else if (bytes != null) {
        data = bytes;
      } else {
        return '';
      }
      final doc = PdfDocument(inputBytes: data);
      final extractor = PdfTextExtractor(doc);
      final pageText =
          extractor.extractText(startPageIndex: index, endPageIndex: index).trim();
      doc.dispose();
      return pageText;
    });

    if (_pageCache.length >= _maxCacheSize) {
      _pageCache.remove(_pageCache.keys.first);
    }
    _pageCache[index] = text;
    return text;
  }

  /// Synchronous read from cache; returns '' if the page hasn't been loaded yet.
  String getPage(int index) => _pageCache[index] ?? '';

  /// Returns up to [maxChars] characters for the page at [pageIndex] (from cache).
  String getContextWindow(int pageIndex, {int maxChars = 2000}) {
    final text = getPage(pageIndex);
    return text.length > maxChars ? text.substring(0, maxChars) : text;
  }

  void dispose() {
    _filePath = null;
    _bytes = null;
    _pageCache.clear();
    _totalPages = 0;
  }
}

