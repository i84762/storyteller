import 'subscription_tier.dart';

enum AIProvider { geminiCloud, openAICloud, onDevice }

class AISource {
  final SubscriptionTier tier;
  final AIProvider provider;
  final String? byokApiKey;

  const AISource({
    required this.tier,
    required this.provider,
    this.byokApiKey,
  });
}
