import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_source.dart';
import '../models/subscription_tier.dart';
import '../providers/model_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/model_selector_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.geminiCloud;
  bool _keyObscured = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<ModelProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Select AI Source',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...SubscriptionTier.values.map((t) => ModelSelectorCard(tier: t)),
          const Divider(height: 40),
          if (modelProvider.currentTier == SubscriptionTier.byok) ...[
            const Text(
              'BYOK Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AIProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: AIProvider.geminiCloud,
                  child: Text('Gemini (Google)'),
                ),
                DropdownMenuItem(
                  value: AIProvider.openAICloud,
                  child: Text('OpenAI (GPT)'),
                ),
              ],
              onChanged: (v) => setState(() => _selectedProvider = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keyController,
              obscureText: _keyObscured,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _keyObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _keyObscured = !_keyObscured),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save API Key'),
              onPressed: () async {
                final key = _keyController.text.trim();
                if (key.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter an API key')),
                  );
                  return;
                }
                await modelProvider.setByokKey(key, _selectedProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('API key saved securely ✓')),
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.upgrade),
            label: const Text('Manage Subscriptions'),
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
          ),
        ],
      ),
    );
  }
}
