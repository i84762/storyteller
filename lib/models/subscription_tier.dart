enum SubscriptionTier {
  free,
  premium,
  byok,
  onDevice,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.byok:
        return 'Bring Your Own Key';
      case SubscriptionTier.onDevice:
        return 'On-Device (Privacy Mode)';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return 'Limited daily requests using Gemini Free tier';
      case SubscriptionTier.premium:
        return 'Unlimited requests via developer key & token packs';
      case SubscriptionTier.byok:
        return 'Use your own Gemini or OpenAI key with a small platform fee';
      case SubscriptionTier.onDevice:
        return 'Private, hardware-accelerated AI running fully on your device';
    }
  }

  String get priceLabel {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return '£1.99/month';
      case SubscriptionTier.byok:
        return '20p/month platform fee';
      case SubscriptionTier.onDevice:
        return '£2.99/month';
    }
  }
}
