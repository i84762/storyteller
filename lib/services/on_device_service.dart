import 'package:flutter/services.dart';

/// Drives Gemini Nano on-device inference via Google AICore.
///
/// Requires AICore to be installed and the device to support Gemini Nano
/// (Pixel 8+, Galaxy S24 Ultra, S25 Ultra, S26 Ultra, and similar flagships).
///
/// Falls back to a clear error message when AICore is unavailable so the
/// caller can surface it to the user instead of silently returning garbage.
class OnDeviceService {
  static const _channel =
      MethodChannel('com.storyteller.storyteller/gemini_nano');

  bool? _available; // null = not yet checked

  /// Returns true if Gemini Nano is available and ready on this device.
  Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    try {
      _available =
          await _channel.invokeMethod<bool>('checkAvailability') ?? false;
    } on PlatformException {
      _available = false;
    }
    return _available!;
  }

  /// Runs [userPrompt] through Gemini Nano.
  ///
  /// [systemPrompt] is prepended as context (AICore doesn't have a separate
  /// system-instruction field, so we combine them for a single prompt).
  Future<String> generateContent(String systemPrompt, String userPrompt) async {
    final ready = await isAvailable();
    if (!ready) {
      throw OnDeviceUnavailableException(
        'Gemini Nano is not available on this device or has not been '
        'downloaded yet. Open Google Play and search for "Google AI Core" '
        'to install it, then restart the app.',
      );
    }

    // Combine system + user prompt since AICore takes a single text input.
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

