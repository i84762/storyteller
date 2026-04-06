import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;
  final String model;

  OpenAIService({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
  });

  Future<String> generateContent(
    String systemPrompt,
    String userPrompt, {
    int maxOutputTokens = 512,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': maxOutputTokens,
      'temperature': 0.4,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body);
    return json['choices'][0]['message']['content'] as String;
  }

  int estimateTokens(String text) => (text.length / 4).ceil();
}
