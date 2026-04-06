import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_tier.dart';
import '../providers/model_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

class ModelSelectorCard extends StatelessWidget {
  final SubscriptionTier tier;
  const ModelSelectorCard({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<ModelProvider>();
    final subProvider = context.watch<SubscriptionProvider>();
    final isSelected = modelProvider.currentTier == tier;
    final isUnlocked = _isUnlocked(tier, subProvider);

    return GestureDetector(
      onTap: isUnlocked ? () => _select(context, tier) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
        ),
        child: Row(
          children: [
            _tierIcon(tier),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock, size: 14, color: Colors.grey),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tier.description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              tier.priceLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUnlocked(SubscriptionTier tier, SubscriptionProvider sub) {
    if (AppConstants.testMode) return true;
    switch (tier) {
      case SubscriptionTier.free:
        return true;
      case SubscriptionTier.premium:
        return sub.isPremium;
      case SubscriptionTier.byok:
        return sub.isByokActive;
      case SubscriptionTier.onDevice:
        return sub.isOnDeviceUnlocked;
    }
  }

  Widget _tierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const Icon(Icons.cloud_outlined, color: Colors.blue);
      case SubscriptionTier.premium:
        return const Icon(Icons.workspace_premium, color: Colors.amber);
      case SubscriptionTier.byok:
        return const Icon(Icons.key, color: Colors.green);
      case SubscriptionTier.onDevice:
        return const Icon(Icons.memory, color: Colors.purple);
    }
  }

  Future<void> _select(BuildContext context, SubscriptionTier tier) async {
    await context.read<ModelProvider>().switchTier(tier);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${tier.displayName}')),
      );
    }
  }
}
