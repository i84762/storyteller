enum IntentType { navigate, control, inquire, unknown }

class IntentResult {
  final IntentType intent;
  final String action;
  final String rawResponse;

  const IntentResult({
    required this.intent,
    required this.action,
    required this.rawResponse,
  });

  factory IntentResult.unknown(String raw) => IntentResult(
        intent: IntentType.unknown,
        action: raw,
        rawResponse: raw,
      );
}
