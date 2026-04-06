import 'package:flutter/services.dart';

/// Drives Gemini Nano on-device inference via ML Kit GenAI Prompt API.
///
/// Supported devices: Samsung Galaxy S25/S26 series, Pixel 9+, and other
/// flagships. Gemini Nano must be downloaded — call [ensureDownloaded] first.
///
/// Falls back to a clear error message when unavailable so the caller can
/// surface it to the user instead of silently returning garbage.
class OnDeviceService {
  static const _channel =
      MethodChannel('com.storyteller.storyteller/gemini_nano');

  String? _cachedStatus; // null = not yet checked

  /// Returns true if Gemini Nano is fully available and ready.
  Future<bool> isAvailable() async {
    final status = await checkStatus();
    return status == 'available';
  }

  /// Returns one of: 'available', 'downloadable', 'downloading', 'unavailable'
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

  /// Invalidates the cached status so the next call re-checks.
  void invalidateCache() => _cachedStatus = null;

  /// Triggers a download if Gemini Nano is in 'downloadable' state.
  /// Returns true if download was started or model is already available.
  Future<bool> ensureDownloaded() async {
    try {
      _cachedStatus = null; // force re-check after download attempt
      return await _channel.invokeMethod<bool>('downloadModel') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Runs [userPrompt] through Gemini Nano.
  ///
  /// [systemPrompt] is prepended as context since the Prompt API takes a
  /// single text input without a separate system-instruction field.
  Future<String> generateContent(String systemPrompt, String userPrompt) async {
    final ready = await isAvailable();
    if (!ready) {
      final status = await checkStatus();
      final hint = status == 'downloadable'
          ? 'Tap "Download Gemini Nano" in Settings → AI Source to enable it.'
          : status == 'downloading'
              ? 'Gemini Nano is currently downloading. Please wait.'
              : 'This device does not support on-device AI, or AICore is not '
                  'installed. Search "Google AI Core" on the Play Store.';
      throw OnDeviceUnavailableException(hint);
    }

    final combined = systemPrompt.trim().isEmpty
        ? userPrompt
        : '${systemPrompt.trim()}\n\n${userPrompt.trim()}';

    try {
      final result = await _channel.invokeMethod<String>(
        'generate',
        {'prompt': combined},
      );
      return result ?? '';
    } on PlatformException catch (e) {
      throw OnDeviceUnavailableException(
          'On-device AI error: ${e.message ?? e.code}');
    }
  }

  int estimateTokens(String text) => (text.length / 4).ceil();
}

class OnDeviceUnavailableException implements Exception {
  final String message;
  const OnDeviceUnavailableException(this.message);

  @override
  String toString() => message;
}

