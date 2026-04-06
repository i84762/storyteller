import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Wraps image-generation backends.
///
/// Priority:
/// 1. Pollinations.ai — always available, free, no key required.
/// 2. OpenAI DALL-E 3 — higher quality, requires BYOK OpenAI key.
/// 3. Gemini Imagen 3 — requires billing-enabled Gemini key.
class ImageGenerationService {
  static const _pollinationsBase = 'https://image.pollinations.ai/prompt';

  /// Generates an image via Pollinations.ai (free, no key, ~5–15 s).
  /// Returns raw JPEG bytes or null on failure.
  static Future<Uint8List?> generatePollinations(String prompt) async {
    try {
      final encoded = Uri.encodeComponent(prompt);
      final url = Uri.parse(
        '$_pollinationsBase/$encoded?width=768&height=512&nologo=true&model=flux&seed=${DateTime.now().millisecondsSinceEpoch % 9999}',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  /// Generates an image using OpenAI DALL-E 3 (BYOK OpenAI).
  static Future<Uint8List?> generateOpenAI(
      String apiKey, String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/images/generations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'dall-e-3',
              'prompt': prompt,
              'n': 1,
              'size': '1024x1024',
              'response_format': 'b64_json',
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final b64 = (json['data'] as List).first['b64_json'] as String;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Generates an image using Google Gemini Imagen 3.
  static Future<Uint8List?> generateGemini(
      String apiKey, String prompt) async {
    try {
      const model = 'imagen-3.0-generate-001';
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:predict?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'instances': [
                {'prompt': prompt}
              ],
              'parameters': {'sampleCount': 1, 'aspectRatio': '16:9'},
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = json['predictions'] as List?;
      if (predictions == null || predictions.isEmpty) return null;
      final b64 = predictions.first['bytesBase64Encoded'] as String?;
      if (b64 == null) return null;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }
}
