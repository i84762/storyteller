import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  Future<bool> init() async {
    _isAvailable = await _stt.initialize(
      onError: (error) => _isListening = false,
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        }
      },
    );
    return _isAvailable;
  }

  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isAvailable) return null;
    String? result;

    _isListening = true;
    await _stt.listen(
      onResult: (r) {
        if (r.finalResult) {
          result = r.recognizedWords;
          _isListening = false;
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );

    // Wait for listening to complete
    while (_stt.isListening) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _isListening = false;
    return result;
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
  }

  void dispose() {
    _stt.cancel();
  }
}
