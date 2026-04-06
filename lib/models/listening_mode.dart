import 'package:flutter/material.dart';

enum ListeningMode {
  /// Raw TTS — no AI involved. Default.
  wordToWord,

  /// AI condenses each page to 3-5 sentences.
  summary,

  /// AI extracts only the most important sentences.
  skimmed,

  /// AI restructures content for exam preparation.
  study,

  /// AI reads the text and weaves in contextual explanations.
  deepDive,

  /// AI rewrites dry text as an engaging narrative.
  storyteller,

  /// AI filters content to a user-specified topic.
  focus,

  /// AI pre-tests the listener with questions, then summarises the page.
  quiz,
}

extension ListeningModeX on ListeningMode {
  String get displayName {
    switch (this) {
      case ListeningMode.wordToWord:
        return 'Word for Word';
      case ListeningMode.summary:
        return 'Page Summary';
      case ListeningMode.skimmed:
        return 'Skimmed';
      case ListeningMode.study:
        return 'Study Mode';
      case ListeningMode.deepDive:
        return 'Deep Dive';
      case ListeningMode.storyteller:
        return 'Storyteller';
      case ListeningMode.focus:
        return 'Focus Mode';
      case ListeningMode.quiz:
        return 'Quiz Mode';
    }
  }

  String get description {
    switch (this) {
      case ListeningMode.wordToWord:
        return 'Reads the page exactly as written — no AI processing.';
      case ListeningMode.summary:
        return 'AI condenses each page into 3–5 key sentences.';
      case ListeningMode.skimmed:
        return 'AI picks only the most important sentences on each page.';
      case ListeningMode.study:
        return 'AI highlights definitions, key facts, and must-know terms for exams.';
      case ListeningMode.deepDive:
        return 'AI reads the text and adds brief contextual explanations.';
      case ListeningMode.storyteller:
        return 'AI rewrites dry content as an engaging, narrative-style story.';
      case ListeningMode.focus:
        return 'AI filters each page to only what\'s relevant to your chosen topic.';
      case ListeningMode.quiz:
        return 'AI asks study questions about each page before summarising it.';
    }
  }

  IconData get icon {
    switch (this) {
      case ListeningMode.wordToWord:
        return Icons.text_fields;
      case ListeningMode.summary:
        return Icons.compress;
      case ListeningMode.skimmed:
        return Icons.fast_forward;
      case ListeningMode.study:
        return Icons.school;
      case ListeningMode.deepDive:
        return Icons.biotech;
      case ListeningMode.storyteller:
        return Icons.auto_stories;
      case ListeningMode.focus:
        return Icons.center_focus_strong;
      case ListeningMode.quiz:
        return Icons.quiz;
    }
  }

  Color get color {
    switch (this) {
      case ListeningMode.wordToWord:
        return Colors.blueGrey;
      case ListeningMode.summary:
        return Colors.teal;
      case ListeningMode.skimmed:
        return Colors.cyan;
      case ListeningMode.study:
        return Colors.orange;
      case ListeningMode.deepDive:
        return Colors.indigo;
      case ListeningMode.storyteller:
        return Colors.purple;
      case ListeningMode.focus:
        return Colors.green;
      case ListeningMode.quiz:
        return Colors.red;
    }
  }

  bool get isAiPowered => this != ListeningMode.wordToWord;

  /// Whether this mode requires the user to supply a topic string.
  bool get requiresTopic => this == ListeningMode.focus;
}
