import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class TtsService {
  final FlutterTts _tts = FlutterTts();
  TtsState state = TtsState.stopped;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _language = 'en-US';

  Function()? onComplete;
  Function(String)? onError;

  Future<void> init() async {
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      state = TtsState.stopped;
      onComplete?.call();
    });

    _tts.setErrorHandler((msg) {
      state = TtsState.stopped;
      onError?.call(msg);
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    state = TtsState.playing;
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
    state = TtsState.paused;
  }

  Future<void> stop() async {
    await _tts.stop();
    state = TtsState.stopped;
  }

  Future<void> resume() async {
    state = TtsState.playing;
    // flutter_tts resumes via speak on most platforms
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  Future<void> speedUp() => setSpeechRate(_speechRate + 0.1);
  Future<void> slowDown() => setSpeechRate(_speechRate - 0.1);

  double get speechRate => _speechRate;

  Future<void> dispose() async {
    await _tts.stop();
  }
}
