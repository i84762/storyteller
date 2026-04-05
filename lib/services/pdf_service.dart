import 'dart:io';
import 'dart:isolate';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  List<String> _pages = [];
  int _totalPages = 0;

  List<String> get pages => _pages;
  int get totalPages => _totalPages;

  Future<void> loadFromPath(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    _pages = await Isolate.run(() => _extractPages(bytes));
    _totalPages = _pages.length;
  }

  Future<void> loadFromBytes(List<int> bytes) async {
    _pages = await Isolate.run(() => _extractPages(bytes));
    _totalPages = _pages.length;
  }

  static List<String> _extractPages(List<int> bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    final extractor = PdfTextExtractor(document);
    final pages = <String>[];
    for (int i = 0; i < count; i++) {
      pages.add(extractor.extractText(startPageIndex: i, endPageIndex: i).trim());
    }
    document.dispose();
    return pages;
  }

  String getPage(int index) {
    if (index < 0 || index >= _pages.length) return '';
    return _pages[index];
  }

  /// Returns up to [maxChars] characters of context around [pageIndex]
  String getContextWindow(int pageIndex, {int maxChars = 2000}) {
    final text = getPage(pageIndex);
    return text.length > maxChars ? text.substring(0, maxChars) : text;
  }

  void dispose() {
    _pages = [];
    _totalPages = 0;
  }
}

