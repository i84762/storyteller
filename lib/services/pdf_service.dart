import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  List<String> _pages = [];
  String _fullText = '';
  int _totalPages = 0;

  List<String> get pages => _pages;
  String get fullText => _fullText;
  int get totalPages => _totalPages;

  Future<void> loadFromPath(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    await _processBytes(bytes);
  }

  Future<void> loadFromBytes(List<int> bytes) async {
    await _processBytes(bytes);
  }

  Future<void> _processBytes(List<int> bytes) async {
    final document = PdfDocument(inputBytes: bytes);
    _totalPages = document.pages.count;
    _pages = [];

    final extractor = PdfTextExtractor(document);
    for (int i = 0; i < _totalPages; i++) {
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      _pages.add(text.trim());
    }

    _fullText = _pages.join('\n\n');
    document.dispose();
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
    _fullText = '';
    _totalPages = 0;
  }
}
