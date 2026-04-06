import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefVoiceName = 'tts_voice_name';
const _kPrefVoiceLocale = 'tts_voice_locale';
const _kPrefLanguage = 'tts_language';

/// A [BaseAudioHandler] that drives [FlutterTts] and exposes an Android
/// foreground-service media session so users can control playback from the
/// notification shade, lock screen, and Bluetooth controls.
class TtsAudioHandler extends BaseAudioHandler {
  final FlutterTts _tts = FlutterTts();
  double _speechRate = 1.0;
  String _selectedLanguage = 'en-US';
  Map<String, String>? _selectedVoice;

  // Callbacks wired up by ReaderProvider so notification controls
  // can drive page navigation / resume.
  VoidCallback? onCompleted;
  VoidCallback? onSkipNext;
  VoidCallback? onSkipPrevious;
  VoidCallback? onResumeRequested;
  /// Called for each word boundary during TTS playback.
  /// [start] and [end] are character offsets *within the text passed to speakText*.
  void Function(int start, int end, String word)? onWordBoundary;

  String get selectedLanguage => _selectedLanguage;
  Map<String, String>? get selectedVoice => _selectedVoice;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString(_kPrefLanguage) ?? 'en-US';
    final voiceName = prefs.getString(_kPrefVoiceName);
    final voiceLocale = prefs.getString(_kPrefVoiceLocale);
    if (voiceName != null && voiceLocale != null) {
      _selectedVoice = {'name': voiceName, 'locale': voiceLocale};
    }

    await _tts.setLanguage(_selectedLanguage);
    if (_selectedVoice != null) {
      await _tts.setVoice(_selectedVoice!);
    }
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setProgressHandler((String text, int start, int end, String word) {
      onWordBoundary?.call(start, end, word);
    });

    _tts.setCompletionHandler(() {
      _setPlaybackState(playing: false);
      onCompleted?.call();
    });
    _tts.setErrorHandler((_) => _setPlaybackState(playing: false));
  }

  // ── Voice / language management ─────────────────────────────────────────

  /// Returns all voices installed on the device.
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw == null) return [];
      return (raw as List)
          .map((v) => Map<String, String>.from(v as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Changes the TTS engine language and persists the choice.
  /// Clears any previously-selected voice so the engine picks a default.
  Future<void> setLanguage(String languageCode) async {
    _selectedLanguage = languageCode;
    _selectedVoice = null;
    await _tts.setLanguage(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLanguage, languageCode);
    await prefs.remove(_kPrefVoiceName);
    await prefs.remove(_kPrefVoiceLocale);
  }

  /// Applies a specific installed voice and persists the choice.
  Future<void> setVoice(Map<String, String> voice) async {
    _selectedVoice = voice;
    await _tts.setVoice(voice);
    final locale = voice['locale'];
    if (locale != null && locale.isNotEmpty) {
      _selectedLanguage = locale;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefVoiceName, voice['name'] ?? '');
    await prefs.setString(_kPrefVoiceLocale, voice['locale'] ?? '');
    await prefs.setString(_kPrefLanguage, _selectedLanguage);
  }

  // ── Playback ────────────────────────────────────────────────────────────

  /// Speaks [text] and updates the media notification with [title] / [subtitle].
  Future<void> speakText(
    String text, {
    required String title,
    String subtitle = '',
  }) async {
    if (text.isEmpty) return;

    mediaItem.add(MediaItem(
      id: 'current_page',
      title: title,
      artist: subtitle,
      displayTitle: title,
      displaySubtitle: subtitle,
    ));

    _setPlaybackState(playing: true);
    await _tts.speak(text);
  }

  // ── BaseAudioHandler overrides ──────────────────────────────────────────

  @override
  Future<void> play() async {
    onResumeRequested?.call();
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
    _setPlaybackState(playing: false);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();

  // ── Speech-rate helpers ─────────────────────────────────────────────────

  static const double minRate = 0.25;
  static const double maxRate = 2.0;
  static const double rateStep = 0.25;

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(minRate, maxRate);
    await _tts.setSpeechRate(_speechRate);
  }

  Future<void> speedUp() => setSpeechRate(_speechRate + rateStep);
  Future<void> slowDown() => setSpeechRate(_speechRate - rateStep);

  double get speechRate => _speechRate;

  // ── Internal helpers ────────────────────────────────────────────────────

  void _setPlaybackState({required bool playing}) {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.ready,
      playing: playing,
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
    ));
  }
}

