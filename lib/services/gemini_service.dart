import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeminiService {
  final String apiKey;
  final String model;

  GeminiService({
    required this.apiKey,
    this.model = AppConstants.geminiFlashModel,
  });

  Future<String> generateContent(
    String systemPrompt,
    String userPrompt, {
    int maxOutputTokens = 512,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': maxOutputTokens,
        'temperature': 0.4,
      }
    });

    // Retry loop: up to 3 attempts with backoff on rate-limit (429).
    for (int attempt = 0; attempt < 3; attempt++) {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['candidates'][0]['content']['parts'][0]['text'] as String;
      }

      if (response.statusCode == 429) {
        // Rate limited — wait progressively longer before retrying.
        final waitSeconds = [15, 45][attempt.clamp(0, 1)];
        await Future.delayed(Duration(seconds: waitSeconds));
        continue;
      }

      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }

    throw Exception('Gemini API: exceeded retry limit due to rate limiting');
  }

  /// Estimate token count (rough: 1 token ≈ 4 chars)
  int estimateTokens(String text) => (text.length / 4).ceil();
}
