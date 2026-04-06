import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_record.dart';
import '../models/listening_mode.dart';
import '../models/offline_config.dart';
import '../models/reading_tone.dart';
import '../services/book_offline_processor.dart';
import '../services/library_service.dart';
import '../services/notification_service.dart';
import '../services/offline_library_service.dart';
import '../services/page_cache_service.dart';
import '../services/pdf_service.dart';
import '../services/audio_handler.dart';
import '../services/stt_service.dart';
import 'model_provider.dart';

enum ReaderState { idle, loading, reading, paused, listening }

/// A word and its character position inside the spoken text.
class WordSpan {
  final String text;
  final int start; // inclusive char offset in spoken text
  final int end;   // exclusive char offset in spoken text
  const WordSpan(this.text, this.start, this.end);
}

class ReaderProvider extends ChangeNotifier {
  final PdfService _pdfService = PdfService();
  final SttService _sttService = SttService();
  final TtsAudioHandler _audioHandler;
  final LibraryService _libraryService = LibraryService();

  /// Set by the ProxyProvider in app.dart after both providers are alive.
  ModelProvider? modelProvider;

  ReaderProvider(this._audioHandler);

  // ── Listening mode ────────────────────────────────────────────────────────
  ListeningMode _listeningMode = ListeningMode.wordToWord;
  String? _focusTopic;

  /// Per-page cache of AI-transformed text; cleared on mode / language / PDF change.
  final Map<int, String> _transformedCache = {};

  /// Page currently being prefetched in the background. null = idle.
  int? _prefetchingPage;

  /// Maximum number of pages to look ahead when prefetching.
  static const int _prefetchLookahead = 2;

  // ── Tone ──────────────────────────────────────────────────────────────────
  ReadingTone _tone = ReadingTone.neutral;
  ReadingTone get tone => _tone;

  // ── Persistent AI cache ───────────────────────────────────────────────────
  final PageCacheService _pageCache = PageCacheService();

  // ── Pictorial mode image state ────────────────────────────────────────────
  final Map<int, Uint8List?> _imageCache = {};
  Uint8List? _currentPageImage;
  bool _isGeneratingImage = false;
  Uint8List? get currentPageImage => _currentPageImage;
  bool get isGeneratingImage => _isGeneratingImage;

  bool _pictorialEnabled = false;
  bool get pictorialEnabled => _pictorialEnabled;

  void setPictorialEnabled(bool val) {
    _pictorialEnabled = val;
    if (!val) {
      _imageCache.clear();
      _currentPageImage = null;
    }
    notifyListeners();
  }

  // ── Offline processing state ──────────────────────────────────────────────
  final OfflineLibraryService _offlineLibrary = OfflineLibraryService();
  BookOfflineProcessor? _offlineProcessor;
  bool _isProcessingOffline = false;
  int _offlineProgress = 0;
  int _offlineTotal = 0;

  bool get isProcessingOffline => _isProcessingOffline;
  int get offlineProgress => _offlineProgress;
  int get offlineTotal => _offlineTotal;
  List<OfflineConfig> get offlineBooks => _offlineLibrary.configs;
  List<OfflineConfig> offlineConfigsForBook(String path) =>
      _offlineLibrary.forBook(path);

  ListeningMode get listeningMode => _listeningMode;
  String? get focusTopic => _focusTopic;

  void setListeningMode(ListeningMode mode, {String? focusTopic}) {
    _listeningMode = mode;
    _focusTopic = focusTopic;
    _tone = ReadingToneX.defaultFor(mode);
    _transformedCache.clear();
    _prefetchingPage = null;
    _imageCache.clear();
    _currentPageImage = null;
    _clearWordState();
    notifyListeners();
  }

  Future<void> setTone(ReadingTone tone) async {
    if (_tone == tone) return;
    _tone = tone;
    _transformedCache.clear();
    _prefetchingPage = null;
    _imageCache.clear();
    _currentPageImage = null;
    _clearWordState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reading_tone', tone.name);
    notifyListeners();
  }

  // ── Language / voice ──────────────────────────────────────────────────────
  String? _targetLanguage; // null = speak in original document language

  String? get targetLanguage => _targetLanguage;
  String get selectedLanguageCode => _audioHandler.selectedLanguage;
  Map<String, String>? get selectedVoice => _audioHandler.selectedVoice;
  String? get selectedVoiceName => _audioHandler.selectedVoice?['name'];

  Future<void> setTargetLanguage(String? languageCode) async {
    _targetLanguage = languageCode;
    _transformedCache.clear();
    _prefetchingPage = null;
    _clearWordState();
    await _audioHandler.setLanguage(languageCode ?? 'en-US');
    if (_state == ReaderState.reading) {
      await _audioHandler.stop();
      await startReading();
    }
    notifyListeners();
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _audioHandler.setVoice(voice);
    notifyListeners();
  }

  Future<List<Map<String, String>>> getAvailableVoices() =>
      _audioHandler.getAvailableVoices();

  // ── AI state ──────────────────────────────────────────────────────────────
  bool _isTranslating = false;
  String? _aiError;
  int _processingChunk = 0;
  int _totalChunks = 0;

  bool get isTranslating => _isTranslating;
  String? get aiError => _aiError;
  /// Current chunk index (1-based display: add 1 before showing).
  int get processingChunk => _processingChunk;
  /// Total number of chunks for the current AI operation. 0 = unknown.
  int get totalChunks => _totalChunks;

  void clearAiError() {
    _aiError = null;
    notifyListeners();
  }

  // ── Word-by-word tracking ─────────────────────────────────────────────────
  /// The text that is currently (or was last) spoken by TTS for the current page.
  String _spokenText = '';

  /// Pre-built list of word positions inside [_spokenText].
  List<WordSpan> _wordSpans = [];

  /// Fast lookup: absolute char start → word index.
  final Map<int, int> _charToWordIdx = {};

  /// Index into [_wordSpans] of the word being spoken right now.
  int _currentWordIndex = -1;

  /// Character offset into [_spokenText] where the current TTS utterance started
  /// (non-zero after a jump-to-word seek).
  int _speakingFromCharOffset = 0;

  String get spokenText => _spokenText;
  List<WordSpan> get wordSpans => _wordSpans;
  int get currentWordIndex => _currentWordIndex;

  /// The text to display in the reader view: AI-transformed when available,
  /// otherwise the raw page text.
  String get displayText =>
      _spokenText.isNotEmpty ? _spokenText : _pdfService.getPage(_currentPage);

  // ── Reader state ──────────────────────────────────────────────────────────
  ReaderState _state = ReaderState.idle;
  int _currentPage = 0;
  String? _pdfPath;
  String? _lastUserInput;
  String? _lastAssistantResponse;
  String? _errorMessage;

  ReaderState get state => _state;
  int get currentPage => _currentPage;
  int get totalPages => _pdfService.totalPages;
  String? get pdfPath => _pdfPath;
  String? get lastUserInput => _lastUserInput;
  String? get lastAssistantResponse => _lastAssistantResponse;
  String get currentPageText => _pdfService.getPage(_currentPage);
  bool get hasPdf => _pdfPath != null && _pdfService.totalPages > 0;
  String? get errorMessage => _errorMessage;
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Library / recent books ────────────────────────────────────────────────
  List<BookRecord> get recentBooks => _libraryService.sortedBooks;

  void togglePin(String path) {
    _libraryService.togglePin(path);
    notifyListeners();
  }

  void removeBook(String path) {
    _libraryService.remove(path);
    _pageCache.deleteForBook(path);
    _offlineLibrary.remove(path).ignore();
    notifyListeners();
  }

  void _saveProgress() {
    if (_pdfPath == null || _pdfService.totalPages == 0) return;
    _libraryService.addOrUpdate(BookRecord(
      path: _pdfPath!,
      title: _bookTitle,
      lastPage: _currentPage,
      totalPages: _pdfService.totalPages,
      lastOpened: DateTime.now(),
    ));
    notifyListeners();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _libraryService.init();
    await _audioHandler.init();
    await _sttService.init();
    await _pageCache.init();
    await _offlineLibrary.init();
    await NotificationService.init();
    await NotificationService.requestPermission();
    final prefs = await SharedPreferences.getInstance();
    final toneName = prefs.getString('reading_tone');
    if (toneName != null) {
      _tone = ReadingTone.values.firstWhere(
        (t) => t.name == toneName,
        orElse: () => ReadingTone.neutral,
      );
    }

    _audioHandler.onCompleted = _onPageReadComplete;
    _audioHandler.onSkipNext = () => nextPage();
    _audioHandler.onSkipPrevious = () => previousPage();
    _audioHandler.onResumeRequested = () => resume();

    _audioHandler.onWordBoundary = (int start, int end, String word) {
      final absStart = _speakingFromCharOffset + start;
      final idx = _charToWordIdx[absStart];
      if (idx != null && idx != _currentWordIndex) {
        _currentWordIndex = idx;
        notifyListeners();
      }
    };

    notifyListeners(); // refresh UI after library loads
  }

  // ── PDF loading ──────────────────────────────────────────────────────────
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
      await _pdfService.getPageAsync(0);
      _transformedCache.clear();
      _prefetchingPage = null;
      _imageCache.clear();
      _currentPageImage = null;
      _clearWordState();
      _state = ReaderState.idle;
      _saveProgress();
      notifyListeners();
      return true;
    } catch (e) {
      _state = ReaderState.idle;
      _errorMessage = 'Failed to load PDF. The file may be too large or corrupted.';
      notifyListeners();
      return false;
    }
  }

  /// Loads a book from the recent-books list and navigates to its last page.
  Future<bool> loadFromRecord(BookRecord record) async {
    _state = ReaderState.loading;
    notifyListeners();
    try {
      await _pdfService.loadFromPath(record.path);
      _pdfPath = record.path;
      _currentPage =
          record.lastPage.clamp(0, _pdfService.totalPages - 1);
      await _pdfService.getPageAsync(_currentPage);
      _transformedCache.clear();
      _prefetchingPage = null;
      _imageCache.clear();
      _currentPageImage = null;
      _clearWordState();
      _state = ReaderState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _state = ReaderState.idle;
      _errorMessage = 'Could not reopen "${record.title}". File may have moved.';
      notifyListeners();
      return false;
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────
  Future<void> startReading() async {
    if (!hasPdf) return;
    _state = ReaderState.reading;
    notifyListeners();
    final rawText = await _pdfService.getPageAsync(_currentPage);
    final text = await _getTextForMode(_currentPage, rawText);
    _prepareSpokenText(text, 0);
    notifyListeners();
    // Current page is ready — start prefetching ahead in the background.
    _schedulePrefetch(_currentPage + 1);
    if (_pictorialEnabled) {
      _triggerImageGeneration(_currentPage);
    }
    await _audioHandler.speakText(
      text,
      title: _bookTitle,
      subtitle: _modeSubtitle(_currentPage),
    );
  }

  Future<void> pause() async {
    await _audioHandler.pause();
    _state = ReaderState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    _state = ReaderState.reading;
    notifyListeners();
    final rawText = await _pdfService.getPageAsync(_currentPage);
    final text = await _getTextForMode(_currentPage, rawText);
    _prepareSpokenText(text, 0);
    await _audioHandler.speakText(
      text,
      title: _bookTitle,
      subtitle: _modeSubtitle(_currentPage),
    );
  }

  Future<void> stop() async {
    await _audioHandler.stop();
    _state = ReaderState.idle;
    _currentWordIndex = -1;
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (_currentPage < totalPages - 1) {
      await _audioHandler.stop();
      _currentPage++;
      _saveProgress();
      _clearWordState();
      notifyListeners();
      await startReading();
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await _audioHandler.stop();
      _currentPage--;
      _saveProgress();
      _clearWordState();
      notifyListeners();
      await startReading();
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 0 && page < totalPages) {
      await _audioHandler.stop();
      _currentPage = page;
      _saveProgress();
      _clearWordState();
      notifyListeners();
      await startReading();
    }
  }

  /// Stops TTS and resumes from [wordIndex] in the current spoken text.
  Future<void> jumpToWord(int wordIndex) async {
    if (wordIndex < 0 || wordIndex >= _wordSpans.length) return;
    await _audioHandler.stop();
    final span = _wordSpans[wordIndex];
    _currentWordIndex = wordIndex;
    _speakingFromCharOffset = span.start;
    _state = ReaderState.reading;
    notifyListeners();
    final text = _spokenText.substring(span.start);
    await _audioHandler.speakText(
      text,
      title: _bookTitle,
      subtitle: _modeSubtitle(_currentPage),
    );
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
    await _audioHandler.speakText(text, title: 'Assistant', subtitle: _bookTitle);
    if (_state != ReaderState.idle) {
      _state = ReaderState.paused;
      notifyListeners();
    }
  }

  void _onPageReadComplete() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      _saveProgress();
      _clearWordState();
      notifyListeners();
      _loadAndSpeakPage(_currentPage);
    } else {
      _state = ReaderState.idle;
      _currentWordIndex = -1;
      notifyListeners();
    }
  }

  Future<void> _loadAndSpeakPage(int index) async {
    final rawText = await _pdfService.getPageAsync(index);
    final text = await _getTextForMode(index, rawText);
    _prepareSpokenText(text, 0);
    notifyListeners();
    // Current page ready — prefetch ahead.
    _schedulePrefetch(index + 1);
    if (_pictorialEnabled) {
      _triggerImageGeneration(index);
    }
    await _audioHandler.speakText(
      text,
      title: _bookTitle,
      subtitle: _modeSubtitle(index),
    );
  }

  // ── Word span management ──────────────────────────────────────────────────

  void _prepareSpokenText(String text, int charOffset) {
    _spokenText = text;
    _speakingFromCharOffset = charOffset;
    _currentWordIndex = -1;
    _buildWordSpans(text);
  }

  void _buildWordSpans(String text) {
    _wordSpans = [];
    _charToWordIdx.clear();
    final regex = RegExp(r'\S+');
    int wordIdx = 0;
    for (final match in regex.allMatches(text)) {
      _wordSpans.add(WordSpan(match.group(0)!, match.start, match.end));
      _charToWordIdx[match.start] = wordIdx;
      wordIdx++;
    }
  }

  void _clearWordState() {
    _spokenText = '';
    _wordSpans = [];
    _charToWordIdx.clear();
    _currentWordIndex = -1;
    _speakingFromCharOffset = 0;
  }

  // ── AI text transformation ────────────────────────────────────────────────

  /// Returns AI-transformed text for [index]; hits cache first.
  /// Falls back to raw text if AI is unavailable; sets [_aiError] on failure.
  Future<String> _getTextForMode(int index, String rawText) async {
    final isWordToWordNoTranslation =
        _listeningMode == ListeningMode.wordToWord && _targetLanguage == null;
    if (isWordToWordNoTranslation || rawText.trim().isEmpty) return rawText;

    if (modelProvider == null) {
      _aiError = 'AI not initialised. Restart the app and try again.';
      notifyListeners();
      return rawText;
    }

    if (_transformedCache.containsKey(index)) return _transformedCache[index]!;

    // Check persistent disk cache before hitting the AI API.
    final bookPath = _pdfPath;
    if (bookPath != null) {
      final cached = await _pageCache.get(
        bookPath, index, _listeningMode.name, _targetLanguage,
        modelProvider!.currentTierName, _tone.name,
      );
      if (cached != null) {
        _transformedCache[index] = cached;
        return cached;
      }
    }

    _isTranslating = true;
    _processingChunk = 0;
    _totalChunks = 0;
    notifyListeners();

    try {
      final transformed = await modelProvider!.transformPageForMode(
        rawText,
        _listeningMode,
        focusTopic: _focusTopic,
        targetLanguage: _targetLanguage,
        tone: _tone,
        onProgress: (done, total) {
          _processingChunk = done;
          _totalChunks = total;
          notifyListeners();
        },
      );
      final result =
          (transformed != null && transformed.isNotEmpty) ? transformed : rawText;
      if (transformed == null || transformed.isEmpty) {
        _aiError = _listeningMode == ListeningMode.wordToWord
            ? 'Translation failed. Configure an AI source in Settings.'
            : 'AI transformation failed. Reading original text.';
      }
      _transformedCache[index] = result;
      // Persist so the same page/mode/tone/tier never hits the API again.
      if (bookPath != null && result != rawText) {
        _pageCache.put(
          bookPath, index, _listeningMode.name, _targetLanguage,
          modelProvider!.currentTierName, _tone.name, result,
        ).ignore();
      }
      return result;
    } catch (e) {
      _aiError = 'AI unavailable. Check your AI source in Settings.';
      _transformedCache[index] = rawText;
      return rawText;
    } finally {
      _isTranslating = false;
      _processingChunk = 0;
      _totalChunks = 0;
      notifyListeners();
    }
  }

  String _modeSubtitle(int index) {
    final base = 'Page ${index + 1} of $totalPages';
    return _listeningMode == ListeningMode.wordToWord
        ? base
        : '$base · ${_listeningMode.displayName}';
  }

  // ── Background prefetch ───────────────────────────────────────────────────

  /// Whether the current mode requires AI processing.
  bool get _needsAiProcessing =>
      !(_listeningMode == ListeningMode.wordToWord && _targetLanguage == null);

  /// Schedules a silent background prefetch for [page] if it isn't cached yet
  /// and is within the lookahead window. Safe to call multiple times.
  void _schedulePrefetch(int page) {
    if (!_needsAiProcessing) return;
    if (modelProvider == null) return;
    if (page >= totalPages || page < 0) return;
    if (page > _currentPage + _prefetchLookahead) return;
    if (_transformedCache.containsKey(page)) {
      // Already cached — try to push the window one further.
      _schedulePrefetch(page + 1);
      return;
    }
    if (_prefetchingPage == page) return; // already in-flight
    _prefetchingPage = page;
    _prefetchPage(page); // fire and forget
  }

  /// Processes [page] in the background and writes the result to
  /// [_transformedCache]. Shows no loading indicators — completely silent.
  /// After finishing, chains to the next page to keep the lookahead rolling.
  Future<void> _prefetchPage(int page) async {
    try {
      final rawText = await _pdfService.getPageAsync(page);
      if (rawText.trim().isEmpty) return;
      if (_prefetchingPage != page) return;
      if (_transformedCache.containsKey(page)) return;

      // Check persistent cache first.
      final bookPath = _pdfPath;
      if (bookPath != null && modelProvider != null) {
        final cached = await _pageCache.get(
          bookPath, page, _listeningMode.name, _targetLanguage,
          modelProvider!.currentTierName, _tone.name,
        );
        if (cached != null) {
          if (_prefetchingPage == page) _transformedCache[page] = cached;
          return;
        }
      }

      if (_prefetchingPage != page) return;

      final transformed = await modelProvider!.transformPageForMode(
        rawText,
        _listeningMode,
        focusTopic: _focusTopic,
        targetLanguage: _targetLanguage,
        tone: _tone,
      );

      if (_prefetchingPage != page) return;

      if (transformed != null && transformed.isNotEmpty) {
        _transformedCache[page] = transformed;
        if (bookPath != null) {
          _pageCache.put(
            bookPath, page, _listeningMode.name, _targetLanguage,
            modelProvider!.currentTierName, _tone.name, transformed,
          ).ignore();
        }
      }
    } catch (_) {
      // Silent — processed on-demand when page is reached.
    } finally {
      if (_prefetchingPage == page) {
        _prefetchingPage = null;
        _schedulePrefetch(page + 1);
      }
    }
  }

  /// Fire-and-forget: generates and caches a page illustration for pictorial mode.
  Future<void> _triggerImageGeneration(int page) async {
    if (modelProvider == null) return;

    // Serve from in-memory cache immediately if available.
    if (_imageCache.containsKey(page)) {
      if (page == _currentPage) {
        _currentPageImage = _imageCache[page];
        notifyListeners();
      }
      return;
    }

    if (page == _currentPage) {
      _isGeneratingImage = true;
      _currentPageImage = null;
      notifyListeners();
    }

    try {
      final rawText = await _pdfService.getPageAsync(page);
      if (rawText.trim().isEmpty) {
        _imageCache[page] = null;
        return;
      }

      // Use transformed text if available for richer image context.
      final contextText = _transformedCache[page] ?? rawText;

      // Step 1: generate a visual description prompt using text AI.
      final imagePrompt = await modelProvider!.generateImagePrompt(
          contextText, _listeningMode, _tone);
      if (imagePrompt == null || imagePrompt.isEmpty) {
        _imageCache[page] = null;
        return;
      }

      // Step 2: call image generation API.
      final imageBytes = await modelProvider!.generateImage(imagePrompt);
      _imageCache[page] = imageBytes;
      if (page == _currentPage) {
        _currentPageImage = imageBytes;
      }
    } catch (_) {
      _imageCache[page] = null;
    } finally {
      if (page == _currentPage) {
        _isGeneratingImage = false;
        notifyListeners();
      }
    }
  }

  Future<void> speedUp() => _applySpeedChange(_audioHandler.speedUp);
  Future<void> slowDown() => _applySpeedChange(_audioHandler.slowDown);

  /// Sets speech rate directly (e.g. from a slider in Settings).
  Future<void> setSpeechRateDirect(double rate) async {
    await _audioHandler.setSpeechRate(rate);
    if (_state == ReaderState.reading) {
      await _audioHandler.stop();
      await startReading();
    }
    notifyListeners();
  }

  Future<void> _applySpeedChange(Future<void> Function() change) async {
    await change();
    if (_state == ReaderState.reading) {
      await _audioHandler.stop();
      await startReading();
    }
    notifyListeners();
  }

  double get speechRate => _audioHandler.speechRate;

  String get currentPdfContext => _pdfService.getContextWindow(_currentPage);

  String get _bookTitle =>
      _pdfPath?.split(RegExp(r'[/\\]')).last ?? 'StoryTeller';

  // ── Offline processing ────────────────────────────────────────────────────

  Future<void> processForOffline({
    required ListeningMode mode,
    required ReadingTone tone,
  }) async {
    if (modelProvider == null || _pdfPath == null) return;
    _isProcessingOffline = true;
    _offlineProgress = 0;
    _offlineTotal = _pdfService.totalPages;
    notifyListeners();

    final config = OfflineConfig(
      bookPath: _pdfPath!,
      mode: mode,
      tone: tone,
      aiTier: modelProvider!.currentTierName,
      totalPages: _pdfService.totalPages,
    );

    _offlineProcessor = BookOfflineProcessor(
      config: config,
      modelProvider: modelProvider!,
      pageCache: _pageCache,
    );

    bool completed = false;
    await _offlineProcessor!.process(
      onProgress: (done, total) {
        _offlineProgress = done;
        _offlineTotal = total;
        notifyListeners();
        NotificationService.showProgress(
          title: 'Processing "$_bookTitle"',
          progress: done,
          total: total,
        ).ignore();
      },
      onComplete: () {
        completed = true;
      },
    );

    if (completed) {
      await _offlineLibrary.save(config);
      NotificationService.showComplete(_bookTitle).ignore();
    } else {
      await NotificationService.cancel();
    }
    _isProcessingOffline = false;
    _offlineProcessor = null;
    notifyListeners();
  }

  void cancelOfflineProcessing() {
    _offlineProcessor?.cancel();
    _isProcessingOffline = false;
    _offlineProgress = 0;
    _offlineProcessor = null;
    NotificationService.cancel().ignore();
    notifyListeners();
  }

  @override
  void dispose() {
    _sttService.dispose();
    _pdfService.dispose();
    super.dispose();
  }
}
