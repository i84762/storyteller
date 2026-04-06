import 'package:flutter/services.dart';

/// Drives Gemini Nano on-device inference via ML Kit GenAI Prompt API.
///
/// Gemini Nano has a practical sweet-spot of ~600 words per call for fast
/// inference. For longer texts [generateContentChunked] splits on paragraph
/// boundaries and calls the model per chunk, reporting progress via a callback.
class OnDeviceService {
  static const _channel =
      MethodChannel('com.storyteller.storyteller/gemini_nano');

  /// Max words per on-device chunk. Keeps each call well within Nano's
  /// context window and ensures reasonable latency per chunk.
  static const int maxChunkWords = 600;

  String? _cachedStatus;

  Future<bool> isAvailable() async => await checkStatus() == 'available';

  /// Returns: 'available' | 'downloadable' | 'downloading' | 'unavailable'
  Future<String> checkStatus() async {
    if (_cachedStatus != null) return _cachedStatus!;
    try {
      _cachedStatus =
          await _channel.invokeMethod<String>('checkStatus') ?? 'unavailable';
    } on PlatformException {
      _cachedStatus = 'unavailable';
    }
    return _cachedStatus!;
  }

  void invalidateCache() => _cachedStatus = null;

  Future<bool> ensureDownloaded() async {
    try {
      _cachedStatus = null;
      return await _channel.invokeMethod<bool>('downloadModel') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Single-shot generation — combine system + user prompt into one call.
  Future<String> generateContent(String systemPrompt, String userPrompt) async {
    final ready = await isAvailable();
    if (!ready) {
      final status = _cachedStatus ?? 'unavailable';
      final hint = status == 'downloadable'
          ? 'Tap "Download Gemini Nano" in Settings → AI Source to enable it.'
          : status == 'downloading'
              ? 'Gemini Nano is currently downloading. Please wait.'
              : 'On-device AI is not available. Check Settings → AI Source.';
      throw OnDeviceUnavailableException(hint);
    }

    final combined = systemPrompt.trim().isEmpty
        ? userPrompt.trim()
        : '${systemPrompt.trim()}\n\n${userPrompt.trim()}';

    try {
      final result =
          await _channel.invokeMethod<String>('generate', {'prompt': combined});
      return result ?? '';
    } on PlatformException catch (e) {
      throw OnDeviceUnavailableException(
          'On-device AI error: ${e.message ?? e.code}');
    }
  }

  /// Chunked generation for long texts.
  ///
  /// - If [text] word-count ≤ [maxChunkWords], calls [generateContent] once.
  /// - If [truncateOnly] is true, truncates at [maxChunkWords] instead of
  ///   chunking — use for summary/skimmed/focus modes where short output is fine.
  /// - Otherwise splits on paragraph/sentence boundaries and processes each
  ///   chunk sequentially, joining results.
  /// - [onProgress] is called as (completedChunks, totalChunks).
  Future<String> generateContentChunked(
    String systemPrompt,
    String text, {
    bool truncateOnly = false,
    void Function(int done, int total)? onProgress,
  }) async {
    final words = text.trim().split(RegExp(r'\s+'));

    // Fast path: short enough for a single call
    if (words.length <= maxChunkWords) {
      onProgress?.call(0, 1);
      final result = await generateContent(systemPrompt, text);
      onProgress?.call(1, 1);
      return result;
    }

    // Truncate path: modes that produce compact output don't need chunking
    if (truncateOnly) {
      final truncated = _truncateAtBoundary(text, maxChunkWords);
      onProgress?.call(0, 1);
      final result = await generateContent(systemPrompt, truncated);
      onProgress?.call(1, 1);
      return result;
    }

    // Chunk path: split on paragraph/sentence boundaries
    final chunks = _splitIntoChunks(text, maxChunkWords);
    final results = <String>[];

    for (int i = 0; i < chunks.length; i++) {
      onProgress?.call(i, chunks.length);
      final result = await generateContent(systemPrompt, chunks[i]);
      results.add(result.trim());
    }
    onProgress?.call(chunks.length, chunks.length);
    return results.join(' ');
  }

  // ── Chunking helpers ───────────────────────────────────────────────────────

  /// Splits [text] into chunks of at most [maxWords] words, preferring to
  /// break on paragraph boundaries, then sentence boundaries.
  static List<String> _splitIntoChunks(String text, int maxWords) {
    final chunks = <String>[];
    final paragraphs = text.split(RegExp(r'\n\s*\n+'));

    final buf = StringBuffer();
    int bufWords = 0;

    void flush() {
      final s = buf.toString().trim();
      if (s.isNotEmpty) chunks.add(s);
      buf.clear();
      bufWords = 0;
    }

    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;
      final paraWords = trimmed.split(RegExp(r'\s+')).length;

      if (paraWords > maxWords) {
        // Paragraph itself too long — split by sentences
        if (bufWords > 0) flush();
        final sentences = _splitBySentence(trimmed, maxWords);
        chunks.addAll(sentences);
        continue;
      }

      if (bufWords + paraWords > maxWords && bufWords > 0) flush();
      buf.write(trimmed);
      buf.write('\n\n');
      bufWords += paraWords;
    }
    flush();

    return chunks.isEmpty ? [text] : chunks;
  }

  static List<String> _splitBySentence(String para, int maxWords) {
    final sentenceEnd = RegExp(r'(?<=[.!?])\s+');
    final sentences = para.split(sentenceEnd);
    final chunks = <String>[];
    final buf = StringBuffer();
    int bufWords = 0;

    for (final s in sentences) {
      final sw = s.split(RegExp(r'\s+')).length;
      if (bufWords + sw > maxWords && bufWords > 0) {
        chunks.add(buf.toString().trim());
        buf.clear();
        bufWords = 0;
      }
      buf.write(s);
      buf.write(' ');
      bufWords += sw;
    }
    if (buf.isNotEmpty) chunks.add(buf.toString().trim());
    return chunks.isEmpty ? [para] : chunks;
  }

  static String _truncateAtBoundary(String text, int maxWords) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    // Walk back from the limit to find a sentence boundary
    var end = maxWords;
    for (int i = maxWords; i > maxWords - 50 && i > 0; i--) {
      if (words[i - 1].endsWith('.') ||
          words[i - 1].endsWith('!') ||
          words[i - 1].endsWith('?')) {
        end = i;
        break;
      }
    }
    return words.take(end).join(' ');
  }

  int estimateTokens(String text) => (text.length / 4).ceil();
}

class OnDeviceUnavailableException implements Exception {
  final String message;
  const OnDeviceUnavailableException(this.message);
  @override
  String toString() => message;
}

