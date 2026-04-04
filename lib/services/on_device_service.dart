/// Stub for on-device Gemini Nano via google_ai_edge.
/// Replace the body of [generateContent] with the actual google_ai_edge calls
/// once the package is stable and added to pubspec.yaml.
class OnDeviceService {
  bool _isInitialized = false;

  Future<bool> initialize() async {
    // TODO: Initialize google_ai_edge / Gemini Nano
    // Example (when package is available):
    //   final model = GenerativeModel(model: 'gemini-nano');
    //   await model.initialize();
    _isInitialized = true;
    return _isInitialized;
  }

  Future<String> generateContent(String systemPrompt, String userPrompt) async {
    if (!_isInitialized) await initialize();
    // TODO: Replace with real on-device inference call.
    // Returning a mock response for now.
    await Future.delayed(const Duration(milliseconds: 500));
    return 'On-device model response: I heard you say "$userPrompt". '
        '(Connect google_ai_edge package for real inference.)';
  }

  int estimateTokens(String text) => (text.length / 4).ceil();
}
