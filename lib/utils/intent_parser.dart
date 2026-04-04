import 'dart:convert';
import '../models/intent_result.dart';

class IntentParser {
  static IntentResult parse(String llmResponse) {
    try {
      // Try to extract JSON from the response
      final jsonMatch =
          RegExp(r'\{.*\}', dotAll: true).firstMatch(llmResponse);
      if (jsonMatch == null) return IntentResult.unknown(llmResponse);

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final intentStr = (json['intent'] as String? ?? '').toUpperCase();
      final action = json['action'] as String? ?? llmResponse;

      IntentType intent;
      switch (intentStr) {
        case 'NAVIGATE':
          intent = IntentType.navigate;
          break;
        case 'CONTROL':
          intent = IntentType.control;
          break;
        case 'INQUIRE':
          intent = IntentType.inquire;
          break;
        default:
          intent = IntentType.unknown;
      }

      return IntentResult(
        intent: intent,
        action: action,
        rawResponse: llmResponse,
      );
    } catch (_) {
      return IntentResult.unknown(llmResponse);
    }
  }
}
