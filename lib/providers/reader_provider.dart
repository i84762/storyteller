import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_service.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';

enum ReaderState { idle, loading, reading, paused, listening }

class ReaderProvider extends ChangeNotifier {
  final PdfService _pdfService = PdfService();
  final TtsService _ttsService = TtsService();
  final SttService _sttService = SttService();

  ReaderState _state = ReaderState.idle;
  int _currentPage = 0;
  String? _pdfPath;
  String? _lastUserInput;
  String? _lastAssistantResponse;

  ReaderState get state => _state;
  int get currentPage => _currentPage;
  int get totalPages => _pdfService.totalPages;
  String? get pdfPath => _pdfPath;
  String? get lastUserInput => _lastUserInput;
  String? get lastAssistantResponse => _lastAssistantResponse;
  String get currentPageText => _pdfService.getPage(_currentPage);
  bool get hasPdf => _pdfPath != null && _pdfService.totalPages > 0;

  Future<void> init() async {
    await _ttsService.init();
    await _sttService.init();
    _ttsService.onComplete = _onPageReadComplete;
  }

  Future<bool> pickAndLoadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return false;

    _state = ReaderState.loading;
    notifyListeners();

    try {
      final file = result.files.first;
      if (file.path != null) {
        await _pdfService.loadFromPath(file.path!);
        _pdfPath = file.path;
      } else if (file.bytes != null) {
        await _pdfService.loadFromBytes(file.bytes!);
        _pdfPath = file.name;
      }
      _currentPage = 0;
      _state = ReaderState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _state = ReaderState.idle;
      notifyListeners();
      return false;
    }
  }

  Future<void> startReading() async {
    if (!hasPdf) return;
    _state = ReaderState.reading;
    notifyListeners();
    await _ttsService.speak(currentPageText);
  }

  Future<void> pause() async {
    await _ttsService.pause();
    _state = ReaderState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    _state = ReaderState.reading;
    notifyListeners();
    await _ttsService.speak(currentPageText);
  }

  Future<void> stop() async {
    await _ttsService.stop();
    _state = ReaderState.idle;
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (_currentPage < totalPages - 1) {
      await _ttsService.stop();
      _currentPage++;
      notifyListeners();
      await startReading();
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await _ttsService.stop();
      _currentPage--;
      notifyListeners();
      await startReading();
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 0 && page < totalPages) {
      await _ttsService.stop();
      _currentPage = page;
      notifyListeners();
      await startReading();
    }
  }

  Future<String?> listenToUser() async {
    _state = ReaderState.listening;
    notifyListeners();
    final result = await _sttService.listenOnce();
    _lastUserInput = result;
    _state = ReaderState.paused;
    notifyListeners();
    return result;
  }

  Future<void> speakResponse(String text) async {
    _lastAssistantResponse = text;
    notifyListeners();
    await _ttsService.speak(text);
    if (_state != ReaderState.idle) {
      _state = ReaderState.paused;
      notifyListeners();
    }
  }

  void _onPageReadComplete() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
      _ttsService.speak(currentPageText);
    } else {
      _state = ReaderState.idle;
      notifyListeners();
    }
  }

  Future<void> speedUp() => _ttsService.speedUp();
  Future<void> slowDown() => _ttsService.slowDown();

  String get currentPdfContext => _pdfService.getContextWindow(_currentPage);

  @override
  void dispose() {
    _ttsService.dispose();
    _sttService.dispose();
    _pdfService.dispose();
    super.dispose();
  }
}
