import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Plan'),
        centerTitle: true,
      ),
      body: sub.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _PlanCard(
                  icon: Icons.workspace_premium,
                  iconColor: Colors.amber,
                  title: 'Premium Monthly',
                  description:
                      'Unlimited reading with our managed developer key. Includes 5,000 tokens/month.',
                  price: '£1.99/month',
                  productId: AppConstants.iapMonthlySubId,
                  isOwned: sub.isPremium,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  icon: Icons.token,
                  iconColor: Colors.teal,
                  title: '500 Token Pack',
                  description: 'One-time purchase of 500 AI tokens.',
                  price: '£0.99',
                  productId: AppConstants.iapTokenPack500Id,
                  isOwned: false,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  icon: Icons.token,
                  iconColor: Colors.green,
                  title: '2,000 Token Pack',
                  description:
                      'One-time purchase of 2,000 AI tokens. Best value!',
                  price: '£2.49',
                  productId: AppConstants.iapTokenPack2000Id,
                  isOwned: false,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  icon: Icons.key,
                  iconColor: Colors.indigo,
                  title: 'BYOK Platform Fee',
                  description:
                      'Bring your own API key. Pay a small monthly platform fee.',
                  price: '20p/month',
                  productId: AppConstants.iapByokPlatformFeeId,
                  isOwned: sub.isByokActive,
                ),
                const SizedBox(height: 12),
                _PlanCard(
                  icon: Icons.memory,
                  iconColor: Colors.purple,
                  title: 'On-Device Pro',
                  description:
                      'Unlock Gemini Nano for fully private, hardware-accelerated AI on your device.',
                  price: '£2.99/month',
                  productId: AppConstants.iapOnDeviceProId,
                  isOwned: sub.isOnDeviceUnlocked,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: sub.restorePurchases,
                  child: const Text('Restore Purchases'),
                ),
              ],
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String price;
  final String productId;
  final bool isOwned;

  const _PlanCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
    required this.productId,
    required this.isOwned,
  });

  @override
  Widget build(BuildContext context) {
    final sub = context.read<SubscriptionProvider>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            isOwned
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => sub.purchaseProduct(productId),
                    child: Text(price),
                  ),
          ],
        ),
      ),
    );
  }
}
