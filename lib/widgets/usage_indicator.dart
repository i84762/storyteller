import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../models/subscription_tier.dart';
import '../utils/constants.dart';

class UsageIndicator extends StatelessWidget {
  const UsageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelProvider>();
    final tier = model.currentTier;
    final usage = model.usage;

    if (tier == SubscriptionTier.byok || tier == SubscriptionTier.onDevice) {
      return const SizedBox.shrink();
    }

    if (tier == SubscriptionTier.free) {
      final percent =
          (usage.dailyRequestsUsed / AppConstants.freeDailyRequestLimit)
              .clamp(0.0, 1.0);
      return _buildBar(
        context,
        label:
            '${usage.dailyRequestsUsed}/${AppConstants.freeDailyRequestLimit} daily requests',
        percent: percent,
        color: percent > 0.8 ? Colors.red : Colors.orange,
      );
    }

    // Premium: show purchased tokens
    final tokensLabel = '${usage.purchasedTokensRemaining} tokens remaining';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        tokensLabel,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.white70),
      ),
    );
  }

  Widget _buildBar(BuildContext context,
      {required String label,
      required double percent,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            percent: percent,
            lineHeight: 6,
            backgroundColor: Colors.white24,
            progressColor: color,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
