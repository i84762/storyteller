import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_source.dart';
import '../models/subscription_tier.dart';
import '../providers/model_provider.dart';
import '../providers/reader_provider.dart';
import '../utils/constants.dart';
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
    final reader = context.watch<ReaderProvider>();
    final tier = modelProvider.currentTier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [

          // ── SPEECH & VOICE ────────────────────────────────────────────────
          _SectionHeader(icon: Icons.record_voice_over, title: 'Speech & Voice'),
          const SizedBox(height: 12),

          // Output language
          DropdownButtonFormField<String?>(
            value: reader.targetLanguage,
            decoration: const InputDecoration(
              labelText: 'Output Language',
              helperText: 'AI translates content into this language',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.translate),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Original (no translation)'),
              ),
              ...AppConstants.supportedLanguages.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (v) => reader.setTargetLanguage(v),
          ),
          const SizedBox(height: 12),

          // Voice picker tile
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            leading: const Icon(Icons.mic),
            title: Text(
              _friendlyVoiceDisplayName(reader.selectedVoice,
                  reader.selectedVoiceName, reader.selectedLanguageCode),
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _voiceQualityLabel(
                  reader.selectedVoice, reader.selectedLanguageCode),
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showVoicePicker(context, reader),
          ),

          const SizedBox(height: 24),

          // ── AI SOURCE ────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.psychology, title: 'AI Source'),
          const SizedBox(height: 4),
          const Text(
            'Tap a source to activate it. Required for translation and listening modes.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),

          ...SubscriptionTier.values.map((t) => ModelSelectorCard(tier: t)),

          // On-device status notice
          if (tier == SubscriptionTier.onDevice) ...[
            const SizedBox(height: 8),
            _OnDeviceNotice(),
          ],

          // BYOK config (only when that tier is active)
          if (tier == SubscriptionTier.byok) ...[
            const SizedBox(height: 16),
            _SectionHeader(icon: Icons.key, title: 'API Key Configuration'),
            const SizedBox(height: 12),
            DropdownButtonFormField<AIProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
                isDense: true,
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
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_keyObscured
                      ? Icons.visibility
                      : Icons.visibility_off),
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
                    const SnackBar(content: Text('Please enter an API key')),
                  );
                  return;
                }
                await modelProvider.setByokKey(key, _selectedProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API key saved ✓')),
                  );
                }
              },
            ),
          ],

          const SizedBox(height: 24),

          // ── ACCOUNT ───────────────────────────────────────────────────────
          _SectionHeader(icon: Icons.account_circle, title: 'Account'),
          const SizedBox(height: 8),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            leading: const Icon(Icons.upgrade),
            title: const Text('Manage Subscription'),
            subtitle: Text('Current: ${modelProvider.currentTier.displayName}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/subscription'),
          ),

          // ── TEST MODE ─────────────────────────────────────────────────────
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade600),
              ),
              child: Row(
                children: [
                  Icon(Icons.developer_mode,
                      color: Colors.orange.shade400, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEST MODE ACTIVE',
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'All tiers unlocked. Payments bypassed.',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Voice display helpers ─────────────────────────────────────────────────

  /// Returns a human-readable voice name from the raw TTS voice map.
  /// e.g. `hi-in-x-hia-local` → "Hindi (India) · Voice A"
  static String _friendlyVoiceDisplayName(
    Map<String, String>? voice,
    String? rawName,
    String langCode,
  ) {
    if (voice == null && rawName == null) return 'Default voice';
    final locale = voice?['locale'] ?? langCode;
    final name = voice?['name'] ?? rawName ?? '';
    final langLabel = _localeToFriendly(locale);
    final variant = _extractVoiceVariant(name);
    return variant.isNotEmpty ? '$langLabel · $variant' : langLabel;
  }

  /// Returns quality/type label for the subtitle.
  static String _voiceQualityLabel(
      Map<String, String>? voice, String langCode) {
    final locale = voice?['locale'] ?? langCode;
    final name = (voice?['name'] ?? '').toLowerCase();
    final langLabel = _localeToFriendly(locale);
    if (name.contains('network')) return '$langLabel · Online (high quality)';
    if (name.contains('local')) return '$langLabel · Offline';
    return langLabel;
  }

  /// Converts a BCP-47 locale like `hi-in` or `en-US` to a friendly name.
  static String _localeToFriendly(String locale) {
    if (locale.isEmpty) return 'Unknown';
    // Normalise to our map format (e.g. hi-IN)
    final parts = locale.split('-');
    if (parts.length >= 2) {
      final normalised =
          '${parts[0].toLowerCase()}-${parts[1].toUpperCase()}';
      final match = AppConstants.supportedLanguages[normalised];
      if (match != null) return match;
      // Try language-only match
      final lang = parts[0].toLowerCase();
      for (final entry in AppConstants.supportedLanguages.entries) {
        if (entry.key.toLowerCase().startsWith('$lang-')) {
          return entry.value
              .replaceAll(RegExp(r'\s*\(.*?\)'), '')
              .trim();
        }
      }
    }
    return locale;
  }

  /// Extracts a user-friendly variant letter from raw TTS voice names.
  /// `hi-in-x-hia-local` → "Voice A", `en-us-x-sfg-local` → ""
  static String _extractVoiceVariant(String rawName) {
    // Pattern: language-region-x-<code><letter>-quality
    final match =
        RegExp(r'-x-[a-z]{2,3}([a-e])-', caseSensitive: false).firstMatch(rawName);
    if (match != null) {
      final letter = match.group(1)!.toUpperCase();
      return 'Voice $letter';
    }
    return '';
  }

  void _showVoicePicker(BuildContext context, ReaderProvider reader) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VoicePickerSheet(reader: reader),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurpleAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3),
        ),
      ],
    );
  }
}

// ── On-device AI notice ───────────────────────────────────────────────────────

class _OnDeviceNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade400, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'On-device AI (Gemini Nano) requires the model to be '
              'downloaded on your device. Currently returning mock responses. '
              'Full support will be enabled in a future update.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voice picker bottom sheet ─────────────────────────────────────────────────

class _VoicePickerSheet extends StatefulWidget {
  final ReaderProvider reader;
  const _VoicePickerSheet({required this.reader});

  @override
  State<_VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends State<_VoicePickerSheet> {
  List<Map<String, String>>? _voices;
  String _filter = 'all'; // 'all' | 'local' | 'network'

  @override
  void initState() {
    super.initState();
    widget.reader.getAvailableVoices().then((v) {
      if (mounted) setState(() => _voices = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Choose Voice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Showing voices for selected language',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Filter chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FilterChip(label: 'All', value: 'all', current: _filter,
                  onTap: () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Offline', value: 'local', current: _filter,
                  onTap: () => setState(() => _filter = 'local')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Online HD', value: 'network',
                  current: _filter,
                  onTap: () => setState(() => _filter = 'network')),
            ],
          ),
          const Divider(),
          Expanded(child: _buildList(scrollController)),
        ],
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    if (_voices == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final lang = widget.reader.selectedLanguageCode;
    final prefix = lang.split('-').first.toLowerCase();

    var filtered = _voices!
        .where((v) => (v['locale'] ?? '').toLowerCase().startsWith(prefix))
        .toList();
    if (filtered.isEmpty) filtered = _voices!;

    // Apply quality filter
    if (_filter == 'local') {
      filtered = filtered
          .where((v) => (v['name'] ?? '').toLowerCase().contains('local'))
          .toList();
    } else if (_filter == 'network') {
      filtered = filtered
          .where((v) => (v['name'] ?? '').toLowerCase().contains('network'))
          .toList();
    }

    if (filtered.isEmpty) {
      return const Center(
          child: Text('No voices match this filter.',
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final voice = filtered[i];
        final rawName = voice['name'] ?? '';
        final locale = voice['locale'] ?? '';
        final isCurrent = rawName == widget.reader.selectedVoiceName;
        final langLabel =
            _SettingsScreenState._localeToFriendly(locale);
        final variant =
            _SettingsScreenState._extractVoiceVariant(rawName);
        final isNetwork =
            rawName.toLowerCase().contains('network');
        final isLocal = rawName.toLowerCase().contains('local');
        final qualityBadge = isNetwork
            ? 'Online HD'
            : isLocal
                ? 'Offline'
                : '';

        return ListTile(
          leading: Icon(
            isNetwork ? Icons.wifi : Icons.offline_bolt,
            color: isCurrent
                ? Theme.of(ctx).colorScheme.primary
                : (isNetwork ? Colors.teal : Colors.blueGrey),
            size: 22,
          ),
          title: Text(
            variant.isNotEmpty ? '$langLabel · $variant' : langLabel,
            style: TextStyle(
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: qualityBadge.isNotEmpty
              ? Text(qualityBadge,
                  style: TextStyle(
                      fontSize: 11,
                      color: isNetwork
                          ? Colors.teal.shade300
                          : Colors.blueGrey.shade300))
              : null,
          trailing: isCurrent
              ? Icon(Icons.check_circle,
                  color: Theme.of(ctx).colorScheme.primary)
              : null,
          onTap: () async {
            await widget.reader.setVoice(voice);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive
              ? Colors.deepPurple
              : Colors.white.withAlpha(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

