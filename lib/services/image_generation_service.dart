import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Wraps image-generation APIs (OpenAI DALL-E 3 and Google Gemini Imagen 3).
class ImageGenerationService {
  /// Generates an image using OpenAI DALL-E 3.
  /// Returns raw PNG bytes decoded from the base64 response, or null on failure.
  static Future<Uint8List?> generateOpenAI(
    String apiKey,
    String prompt,
  ) async {
    try {
      final response = await http.post(
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
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final b64 = (json['data'] as List).first['b64_json'] as String;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Generates an image using Google Gemini Imagen 3.
  /// Returns raw PNG bytes, or null on failure / quota exceeded.
  static Future<Uint8List?> generateGemini(
    String apiKey,
    String prompt,
  ) async {
    try {
      const model = 'imagen-3.0-generate-001';
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:predict?key=$apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'instances': [
            {'prompt': prompt}
          ],
          'parameters': {'sampleCount': 1, 'aspectRatio': '1:1'},
        }),
      ).timeout(const Duration(seconds: 60));
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
