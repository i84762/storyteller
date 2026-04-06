import 'listening_mode.dart';

/// The stylistic register in which AI rewrites page content.
///
/// Every [ReadingTone] works with any [ListeningMode] — but each mode has a
/// [defaultFor] suggestion that feels most natural out of the box.
enum ReadingTone {
  neutral,
  conversational,
  academic,
  storytelling,
  concise,
  socratic,
  poetic,
  humorous,
}

extension ReadingToneX on ReadingTone {
  String get displayName {
    switch (this) {
      case ReadingTone.neutral:        return 'Neutral';
      case ReadingTone.conversational: return 'Conversational';
      case ReadingTone.academic:       return 'Academic';
      case ReadingTone.storytelling:   return 'Storytelling';
      case ReadingTone.concise:        return 'Concise';
      case ReadingTone.socratic:       return 'Socratic';
      case ReadingTone.poetic:         return 'Poetic';
      case ReadingTone.humorous:       return 'Humorous';
    }
  }

  String get emoji {
    switch (this) {
      case ReadingTone.neutral:        return '⚖️';
      case ReadingTone.conversational: return '💬';
      case ReadingTone.academic:       return '🎓';
      case ReadingTone.storytelling:   return '📖';
      case ReadingTone.concise:        return '✂️';
      case ReadingTone.socratic:       return '🤔';
      case ReadingTone.poetic:         return '🌸';
      case ReadingTone.humorous:       return '😄';
    }
  }

  String get description {
    switch (this) {
      case ReadingTone.neutral:
        return 'Balanced and faithful to the source material.';
      case ReadingTone.conversational:
        return 'Warm and casual — like a friend explaining it naturally.';
      case ReadingTone.academic:
        return 'Precise and scholarly, ideal for study or research.';
      case ReadingTone.storytelling:
        return 'Vivid and narrative, drawing you into the content.';
      case ReadingTone.concise:
        return 'Tight and direct — every word earns its place.';
      case ReadingTone.socratic:
        return 'Thought-provoking — gently challenges you to reflect.';
      case ReadingTone.poetic:
        return 'Lyrical and evocative, letting the prose breathe.';
      case ReadingTone.humorous:
        return 'Light and witty without undermining the substance.';
    }
  }

  /// The tone that feels most natural for a given [ListeningMode].
  static ReadingTone defaultFor(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.wordToWord:   return ReadingTone.neutral;
      case ListeningMode.summary:      return ReadingTone.concise;
      case ListeningMode.skimmed:      return ReadingTone.concise;
      case ListeningMode.study:        return ReadingTone.academic;
      case ListeningMode.deepDive:     return ReadingTone.academic;
      case ListeningMode.storyteller:  return ReadingTone.storytelling;
      case ListeningMode.focus:        return ReadingTone.conversational;
      case ListeningMode.quiz:         return ReadingTone.socratic;
      case ListeningMode.pictorial:    return ReadingTone.neutral;
    }
  }

  /// The prompt fragment appended to any mode's system prompt to shift its
  /// register. Empty for [ReadingTone.neutral] since that is the baseline.
  String get promptInstruction {
    switch (this) {
      case ReadingTone.neutral:
        return '';
      case ReadingTone.conversational:
        return '\nDeliver the content in a warm, conversational tone — '
            'as if a knowledgeable friend is explaining it naturally.';
      case ReadingTone.academic:
        return '\nUse a precise, formal, scholarly tone appropriate for '
            'academic study or professional reading.';
      case ReadingTone.storytelling:
        return '\nUse a vivid, immersive narrative tone. Draw the listener '
            'in with descriptive, story-like language.';
      case ReadingTone.concise:
        return '\nBe extremely concise. Every sentence must be essential. '
            'Cut all filler, repetition, and padding without mercy.';
      case ReadingTone.socratic:
        return '\nUse a reflective, thought-provoking tone. Gently challenge '
            'the listener to think critically and question assumptions.';
      case ReadingTone.poetic:
        return '\nUse evocative, lyrical language. Let the prose breathe '
            'and resonate emotionally without sacrificing clarity.';
      case ReadingTone.humorous:
        return '\nUse a light, witty tone that keeps the content accessible '
            'and occasionally playful, without undermining the substance.';
    }
  }
}
