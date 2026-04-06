import 'package:flutter/foundation.dart';
import '../models/listening_mode.dart';
import '../models/reading_tone.dart';

class AppConstants {
  /// In debug builds every subscription tier is unlocked for testing.
  static const bool testMode = kDebugMode;

  // Free tier limits
  static const int freeDailyRequestLimit = 10;
  static const int freeDailyTokenLimit = 5000;

  // Developer API key (replace with real key before publishing)
  static const String devGeminiApiKey = 'YOUR_DEV_GEMINI_API_KEY';

  // RevenueCat API key
  static const String revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

  // IAP product IDs
  static const String iapMonthlySubId = 'storyteller_monthly_sub';
  static const String iapTokenPack500Id = 'storyteller_tokens_500';
  static const String iapTokenPack2000Id = 'storyteller_tokens_2000';
  static const String iapByokPlatformFeeId = 'storyteller_byok_fee';
  static const String iapOnDeviceProId = 'storyteller_ondevice_pro';

  // Gemini model names
  static const String geminiFlashModel = 'gemini-1.5-flash';
  static const String geminiProModel = 'gemini-1.5-pro';

  /// BCP-47 language codes → display names (ordered by common usage).
  static const Map<String, String> supportedLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'es-ES': 'Spanish',
    'fr-FR': 'French',
    'de-DE': 'German',
    'it-IT': 'Italian',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'nl-NL': 'Dutch',
    'ru-RU': 'Russian',
    'ja-JP': 'Japanese',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'ko-KR': 'Korean',
    'ar-SA': 'Arabic',
    'hi-IN': 'Hindi',
    'tr-TR': 'Turkish',
    'pl-PL': 'Polish',
    'sv-SE': 'Swedish',
    'da-DK': 'Danish',
    'fi-FI': 'Finnish',
    'nb-NO': 'Norwegian',
    'cs-CZ': 'Czech',
    'hu-HU': 'Hungarian',
    'ro-RO': 'Romanian',
    'uk-UA': 'Ukrainian',
    'th-TH': 'Thai',
    'id-ID': 'Indonesian',
    'vi-VN': 'Vietnamese',
    'el-GR': 'Greek',
    'he-IL': 'Hebrew',
  };

  // Intent classification prompt prefix
  static const String intentSystemPrompt = '''
You are a reading assistant. The user is listening to a PDF being read aloud.
Classify the user's spoken input into exactly ONE of these intents:
- NAVIGATE: user wants to go to a page, chapter, or section
- CONTROL: user wants to pause, resume, stop, repeat, speed up, or slow down
- INQUIRE: user wants to ask a question about the content

Respond in JSON: {"intent": "NAVIGATE|CONTROL|INQUIRE", "action": "<specific action or question>"}
''';

  static const String storySystemPrompt = '''
You are StoryTeller, a warm and engaging reading companion.
You are reading a PDF document aloud to the user.
When answering questions about the document, be concise, clear, and helpful.
When navigating, confirm the action taken.
When controlling playback, acknowledge the command warmly.
''';

  // ── Listening-mode transformation prompts ─────────────────────────────────

  /// Returns the system prompt for AI-powered listening modes.
  ///
  /// All prompts produce plain spoken prose — no markdown, bullets, or headers.
  /// When [targetLanguage] is provided the AI responds in that language; for
  /// [ListeningMode.wordToWord] with a language set, the prompt becomes a
  /// pure-translation instruction.
  static String listeningModePrompt(
    ListeningMode mode, {
    String? focusTopic,
    String? targetLanguage,
    ReadingTone tone = ReadingTone.neutral,
  }) {
    final langInstr = _langInstruction(targetLanguage);
    final toneInstr = tone.promptInstruction;

    switch (mode) {
      case ListeningMode.wordToWord:
        if (targetLanguage == null) return ''; // raw passthrough
        final langName =
            supportedLanguages[targetLanguage] ?? targetLanguage;
        return '''
Translate the following text into $langName.
Preserve all meaning and detail faithfully. Write as natural spoken prose.
Do not use bullet points, numbered lists, headers, or markdown symbols.$toneInstr
''';

      case ListeningMode.summary:
        return '''
You are an AI reading assistant.
Summarise the following page in 3 to 5 clear, complete sentences that capture the main ideas.
Write as natural prose suitable to be read aloud.
Do not use bullet points, numbered lists, markdown formatting, or headers.
Speak directly as if narrating to a listener.$toneInstr$langInstr
''';

      case ListeningMode.skimmed:
        return '''
You are an AI reading assistant.
From the following text, extract the 5 most important sentences that convey the core meaning.
Join them naturally as spoken prose, filling in only the minimum connective words needed.
Do not add new information, bullet points, or markdown formatting.
The result must sound natural when read aloud.$toneInstr$langInstr
''';

      case ListeningMode.study:
        return '''
You are an AI study assistant helping a student prepare for an exam.
Transform the following text into a spoken study guide.
Start with a one-sentence statement of the main topic.
Then present the key facts, definitions, and important terms as clear spoken sentences.
End with a one-sentence "remember this" takeaway.
Do not use bullet points, numbered lists, or markdown. Write as natural speech.$toneInstr$langInstr
''';

      case ListeningMode.deepDive:
        return '''
You are an educational narrator.
Read the following text and enrich it with brief contextual explanations.
For each major concept, add one clarifying sentence of useful background or real-world context immediately after it is introduced.
Keep all additions concise. The result should flow naturally as spoken audio.
Do not use bullet points or markdown.$toneInstr$langInstr
''';

      case ListeningMode.storyteller:
        return '''
You are a skilled audiobook narrator.
Rewrite the following text in an engaging, narrative voice as if telling a compelling story.
Preserve every fact and piece of information, but make the language vivid, fluid, and captivating.
Write as natural flowing prose suitable for listening — no bullet points or markdown.$toneInstr$langInstr
''';

      case ListeningMode.focus:
        final topic =
            focusTopic?.isNotEmpty == true ? focusTopic! : 'the main topic';
        return '''
You are an AI reading assistant. The listener is specifically interested in: $topic.
From the following text, extract and present only the content directly relevant to "$topic".
Write in clear, natural spoken sentences.
If nothing in the text is relevant to "$topic", say exactly:
"This page does not contain information about $topic."
Do not use bullet points, numbered lists, or markdown.$toneInstr$langInstr
''';

      case ListeningMode.quiz:
        return '''
You are an AI study coach.
For the following page of text, do this in order:
First, generate exactly 2 short study questions that test understanding of the key content.
After each question, immediately say "The answer is:" followed by a one-sentence answer.
Then say "Now, here is a summary:" followed by a 2 to 3 sentence summary of the page.
Format for audio only — no bullet points, no numbering, no markdown symbols.
Use natural spoken transitions like "First question:", "Second question:", "The answer is:", "Now, here is a summary:".$toneInstr$langInstr
''';
    }
  }

  static String _langInstruction(String? code) {
    if (code == null) return '';
    final name = supportedLanguages[code] ?? code;
    return '\nRespond in $name.';
  }
}
