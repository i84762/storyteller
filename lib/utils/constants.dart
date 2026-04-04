class AppConstants {
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
}
