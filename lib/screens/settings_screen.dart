import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../providers/model_provider.dart';
import '../providers/theme_provider.dart';
import '../services/audio_handler.dart';
import '../themes/app_theme.dart';
import '../models/ai_source.dart';
import '../models/subscription_tier.dart';

// ── Hub ───────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final model = context.watch<ModelProvider>();
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    final rateDisplay = _rateLabel(reader.speechRate);
    final voiceLabel = _voiceLabel(reader.selectedVoiceName);
    final langLabel = _languageLabel(reader.selectedLanguageCode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _NavTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: theme.isSepia ? 'Warm Sepia' : 'Dark Purple',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _ThemePage()),
            ),
          ),

          // ── Listening ──────────────────────────────────────────────────
          _SectionHeader('Listening'),
          _NavTile(
            icon: Icons.record_voice_over_outlined,
            title: 'Voice & Language',
            subtitle: '$langLabel · $voiceLabel',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _VoiceLanguagePage()),
            ),
          ),
          _NavTile(
            icon: Icons.speed,
            title: 'Playback Speed',
            subtitle: rateDisplay,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _SpeedPage()),
            ),
          ),

          // ── AI Intelligence ────────────────────────────────────────────
          _SectionHeader('AI Intelligence'),
          _NavTile(
            icon: Icons.auto_awesome_outlined,
            title: 'AI Source',
            subtitle: _aiSourceLabel(model.currentTier),
            trailing: _AiStatusDot(model: model),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AiSourcePage()),
            ),
          ),

          // ── Account ────────────────────────────────────────────────────
          _SectionHeader('Account'),
          _NavTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            subtitle: _aiSourceLabel(model.currentTier),
            onTap: () => Navigator.pushNamed(context, '/subscription'),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'StoryTeller v1.0',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.3), fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String _rateLabel(double rate) {
    final display = rate / 0.5;
    return '${display.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×';
  }

  static String _voiceLabel(String? name) {
    if (name == null || name.isEmpty) return 'System default';
    return _parseFriendlyVoiceName(name);
  }

  static String _languageLabel(String code) {
    final parts = code.split('-');
    if (parts.isEmpty) return code;
    return _languageName(parts[0]);
  }

  static String _aiSourceLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free (limited)';
      case SubscriptionTier.onDevice:
        return 'On-device AI';
      case SubscriptionTier.premium:
        return 'Cloud AI (Gemini)';
      case SubscriptionTier.byok:
        return 'Own API key';
      default:
        return tier.displayName;
    }
  }

  static String _parseFriendlyVoiceName(String raw) {
    final lower = raw.toLowerCase();
    final isNetwork = lower.contains('network');
    final quality = isNetwork ? 'Online HD' : 'Offline';

    final parts = lower.split('-');
    final lang = parts.isNotEmpty ? _languageName(parts[0]) : '';
    final region = parts.length > 1 ? parts[1].toUpperCase() : '';

    String variant = '';
    for (int i = parts.length - 1; i >= 0; i--) {
      final p = parts[i];
      if (p == 'local' || p == 'network') continue;
      if (p.length == 1 && RegExp(r'[a-z]').hasMatch(p)) {
        variant = 'Voice ${p.toUpperCase()}';
        break;
      }
    }

    final pieces = [
      if (lang.isNotEmpty) '$lang ($region)',
      if (variant.isNotEmpty) variant,
      quality,
    ];
    return pieces.join(' · ');
  }

  static String _languageName(String code) {
    const map = {
      'en': 'English', 'hi': 'Hindi', 'fr': 'French', 'de': 'German',
      'es': 'Spanish', 'it': 'Italian', 'pt': 'Portuguese', 'zh': 'Chinese',
      'ja': 'Japanese', 'ko': 'Korean', 'ar': 'Arabic', 'ru': 'Russian',
      'nl': 'Dutch', 'pl': 'Polish', 'tr': 'Turkish', 'sv': 'Swedish',
      'da': 'Danish', 'fi': 'Finnish', 'nb': 'Norwegian', 'cs': 'Czech',
      'sk': 'Slovak', 'hu': 'Hungarian', 'ro': 'Romanian', 'bg': 'Bulgarian',
      'uk': 'Ukrainian', 'el': 'Greek', 'he': 'Hebrew', 'th': 'Thai',
      'vi': 'Vietnamese', 'id': 'Indonesian', 'ms': 'Malay', 'bn': 'Bengali',
      'ta': 'Tamil', 'te': 'Telugu', 'mr': 'Marathi', 'gu': 'Gujarati',
      'kn': 'Kannada', 'ml': 'Malayalam', 'pa': 'Punjabi', 'ur': 'Urdu',
    };
    return map[code.toLowerCase()] ?? code.toUpperCase();
  }
}

// ── Theme page ────────────────────────────────────────────────────────────────

class _ThemePage extends StatelessWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose how the app looks. Sepia is easier on the eyes for long reading sessions.',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5),
          ),
          const SizedBox(height: 24),
          _ThemeCard(
            title: 'Warm Sepia',
            subtitle: 'Parchment background · Dark brown text · Book-like feel',
            selected: theme.mode == AppThemeMode.sepia,
            preview: const _SepiaPreview(),
            onTap: () => theme.setMode(AppThemeMode.sepia),
          ),
          const SizedBox(height: 16),
          _ThemeCard(
            title: 'Dark Purple',
            subtitle: 'Near-black background · Soft lavender accents · Night reading',
            selected: theme.mode == AppThemeMode.darkPurple,
            preview: const _DarkPurplePreview(),
            onTap: () => theme.setMode(AppThemeMode.darkPurple),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(height: 100, child: preview),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                color:
                                    cs.onSurface.withValues(alpha: 0.55),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: cs.primary, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SepiaPreview extends StatelessWidget {
  const _SepiaPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F0E3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 10,
              width: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF7B3F00),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          for (int i = 0; i < 3; i++) ...[
            Container(
                height: 6,
                color: const Color(0xFF2C1A0E).withValues(alpha: 0.4)),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}

class _DarkPurplePreview extends StatelessWidget {
  const _DarkPurplePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF100D16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 10,
              width: 120,
              decoration: BoxDecoration(
                  color: const Color(0xFF9B8EC4),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          for (int i = 0; i < 3; i++) ...[
            Container(
                height: 6,
                color: const Color(0xFFE8E0F0).withValues(alpha: 0.35)),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}

// ── Voice & Language page ─────────────────────────────────────────────────────

class _VoiceLanguagePage extends StatefulWidget {
  const _VoiceLanguagePage();

  @override
  State<_VoiceLanguagePage> createState() => _VoiceLanguagePageState();
}

class _VoiceLanguagePageState extends State<_VoiceLanguagePage> {
  List<Map<String, String>> _voices = [];
  bool _loading = true;
  String _filter = 'All';

  static const _languages = [
    ('English', 'en-US'),
    ('Hindi', 'hi-IN'),
    ('French', 'fr-FR'),
    ('German', 'de-DE'),
    ('Spanish', 'es-ES'),
    ('Italian', 'it-IT'),
    ('Portuguese', 'pt-BR'),
    ('Chinese', 'zh-CN'),
    ('Japanese', 'ja-JP'),
    ('Korean', 'ko-KR'),
    ('Arabic', 'ar-SA'),
    ('Russian', 'ru-RU'),
  ];

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    final reader = context.read<ReaderProvider>();
    final voices = await reader.getAvailableVoices();
    if (mounted) setState(() { _voices = voices; _loading = false; });
  }

  List<Map<String, String>> get _filteredVoices {
    if (_filter == 'All') return _voices;
    if (_filter == 'Offline') {
      return _voices.where((v) =>
          !(v['name'] ?? '').toLowerCase().contains('network')).toList();
    }
    return _voices.where((v) =>
        (v['name'] ?? '').toLowerCase().contains('network')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final cs = Theme.of(context).colorScheme;
    final currentLang = reader.selectedLanguageCode;
    final currentVoice = reader.selectedVoiceName;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice & Language')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('OUTPUT LANGUAGE',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final (name, code) = _languages[i];
                final selected = currentLang.toLowerCase()
                    .startsWith(code.split('-')[0].toLowerCase());
                return ChoiceChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (_) async {
                    await reader.setTargetLanguage(code);
                    await _loadVoices();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('VOICE',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: ['All', 'Offline', 'Online HD'].map((f) => FilterChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Voice list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVoices.isEmpty
                    ? Center(
                        child: Text('No voices found',
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5))))
                    : ListView.builder(
                        itemCount: _filteredVoices.length,
                        itemBuilder: (ctx, i) {
                          final v = _filteredVoices[i];
                          final name = v['name'] ?? '';
                          final friendly =
                              SettingsScreen._parseFriendlyVoiceName(name);
                          final isSelected = name == currentVoice;
                          return ListTile(
                            title: Text(friendly),
                            subtitle: Text(name,
                                style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                    fontSize: 11)),
                            trailing: isSelected
                                ? Icon(Icons.check, color: cs.primary)
                                : null,
                            onTap: () => reader.setVoice(v),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Speed page ────────────────────────────────────────────────────────────────

class _SpeedPage extends StatelessWidget {
  const _SpeedPage();

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5];

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final cs = Theme.of(context).colorScheme;
    final raw = reader.speechRate;
    final display = raw / 0.5;

    return Scaffold(
      appBar: AppBar(title: const Text('Playback Speed')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Text(
              '${display.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×',
              style: TextStyle(
                  fontSize: 64, fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ),
          Center(
            child: Text(
              raw == 0.5
                  ? 'Normal speed'
                  : (raw < 0.5 ? 'Slower than normal' : 'Faster than normal'),
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          Slider(
            value: raw.clamp(TtsAudioHandler.minRate, TtsAudioHandler.maxRate),
            min: TtsAudioHandler.minRate,
            max: TtsAudioHandler.maxRate,
            divisions: ((TtsAudioHandler.maxRate - TtsAudioHandler.minRate) /
                    TtsAudioHandler.rateStep)
                .round(),
            label: '${(raw / 0.5).toStringAsFixed(1)}×',
            onChanged: (v) => reader.setSpeechRateDirect(v),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: _presets.map((r) {
              final label =
                  '${(r / 0.5).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×';
              return ChoiceChip(
                label: Text(label),
                selected: (raw - r).abs() < 0.01,
                onSelected: (_) => reader.setSpeechRateDirect(r),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Speed guide',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 10),
                for (final entry in [
                  (0.5, '1× · Natural, easy to follow'),
                  (0.75, '1.5× · Comfortable, slightly faster'),
                  (1.0, '2× · Efficient, requires focus'),
                  (1.5, '3× · Power listening'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${(entry.$1 / 0.5).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: Text(entry.$2,
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Source page ────────────────────────────────────────────────────────────

class _AiSourcePage extends StatelessWidget {
  const _AiSourcePage();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelProvider>();
    final tier = model.currentTier;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Source')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose how AI processes your books. On-device keeps data private. Cloud gives the best quality.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          _SourceCard(
            title: 'On-device AI',
            subtitle: 'Gemini Nano — private, no internet needed',
            icon: Icons.phone_android,
            selected: tier == SubscriptionTier.onDevice,
            onTap: () => model.switchTier(SubscriptionTier.onDevice),
            body: const _OnDevicePanel(),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: 'Cloud AI',
            subtitle: 'Google Gemini Flash — high quality, requires internet',
            icon: Icons.cloud_outlined,
            selected: tier == SubscriptionTier.premium,
            onTap: () => model.switchTier(SubscriptionTier.premium),
            body: const _CloudPanel(),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: 'Own API Key',
            subtitle: 'Use your Gemini or OpenAI key — no subscription needed',
            icon: Icons.key_outlined,
            selected: tier == SubscriptionTier.byok,
            onTap: () => model.switchTier(SubscriptionTier.byok),
            body: const _ByokPanel(),
          ),
          const SizedBox(height: 12),
          _SourceCard(
            title: 'Free',
            subtitle: 'Limited AI calls per day',
            icon: Icons.lock_open_outlined,
            selected: tier == SubscriptionTier.free,
            onTap: () => model.switchTier(SubscriptionTier.free),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? body;

  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? cs.primary : cs.outline,
          width: selected ? 2 : 1,
        ),
        color: cs.surface,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.5)),
            title: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(subtitle,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 12)),
            trailing: selected
                ? Icon(Icons.radio_button_checked, color: cs.primary)
                : Icon(Icons.radio_button_unchecked,
                    color: cs.onSurface.withValues(alpha: 0.3)),
            onTap: onTap,
          ),
          if (selected && body != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: body!,
            ),
        ],
      ),
    );
  }
}

class _OnDevicePanel extends StatefulWidget {
  const _OnDevicePanel();

  @override
  State<_OnDevicePanel> createState() => _OnDevicePanelState();
}

class _OnDevicePanelState extends State<_OnDevicePanel> {
  bool? _available;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final mm = context.read<ModelProvider>().modelManager;
      final ok = await mm.checkOnDeviceAvailability();
      if (mounted) setState(() => _available = ok);
    } catch (_) {
      if (mounted) setState(() => _available = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_available == null) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_available == true) {
      return _InfoBox(
        color: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        text: 'Gemini Nano is ready on this device.',
      );
    }
    return _InfoBox(
      color: Colors.orange.shade700,
      icon: Icons.warning_amber_outlined,
      text:
          'AICore not found. Install "Google AICore" from the Play Store to use on-device AI.',
    );
  }
}

class _CloudPanel extends StatelessWidget {
  const _CloudPanel();

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      color: Theme.of(context).colorScheme.primary,
      icon: Icons.info_outline,
      text: 'Requires internet. Uses Google Gemini Flash for best quality AI.',
    );
  }
}

class _ByokPanel extends StatefulWidget {
  const _ByokPanel();

  @override
  State<_ByokPanel> createState() => _ByokPanelState();
}

class _ByokPanelState extends State<_ByokPanel> {
  final _ctrl = TextEditingController();
  AIProvider _provider = AIProvider.geminiCloud;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<ModelProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<AIProvider>(
          segments: const [
            ButtonSegment(
                value: AIProvider.geminiCloud, label: Text('Gemini')),
            ButtonSegment(value: AIProvider.openAICloud, label: Text('OpenAI')),
          ],
          selected: {_provider},
          onSelectionChanged: (s) => setState(() => _provider = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'API Key',
            border: const OutlineInputBorder(),
            suffixIcon: _saving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () async {
                      if (_ctrl.text.isEmpty) return;
                      setState(() => _saving = true);
                      await model.setByokKey(_ctrl.text.trim(), _provider);
                      if (mounted) setState(() => _saving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API key saved')));
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: cs.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.onSurface.withValues(alpha: 0.6)),
      title: Text(title,
          style:
              TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }
}

class _AiStatusDot extends StatelessWidget {
  final ModelProvider model;
  const _AiStatusDot({required this.model});

  @override
  Widget build(BuildContext context) {
    final isOnDevice = model.currentTier == SubscriptionTier.onDevice;
    if (!isOnDevice) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBox({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
