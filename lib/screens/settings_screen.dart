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
            title: 'AI Engine',
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

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
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _loadVoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    final reader = context.read<ReaderProvider>();
    final voices = await reader.getAvailableVoices();
    if (mounted) setState(() { _voices = voices; _loading = false; });
  }

  List<Map<String, String>> get _filteredVoices {
    var list = _voices.toList();

    // Type filter
    if (_filter == 'Offline') {
      list = list.where((v) =>
          !(v['name'] ?? '').toLowerCase().contains('network')).toList();
    } else if (_filter == 'Online HD') {
      list = list.where((v) =>
          (v['name'] ?? '').toLowerCase().contains('network')).toList();
    }

    // Search filter — match against friendly name or raw name
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((v) {
        final friendly = SettingsScreen._parseFriendlyVoiceName(v['name'] ?? '');
        return friendly.toLowerCase().contains(q) ||
            (v['name'] ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Sort alphabetically by friendly name
    list.sort((a, b) {
      final fa = SettingsScreen._parseFriendlyVoiceName(a['name'] ?? '');
      final fb = SettingsScreen._parseFriendlyVoiceName(b['name'] ?? '');
      return fa.toLowerCase().compareTo(fb.toLowerCase());
    });

    return list;
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
            child: Row(
              children: [
                Text('VOICE',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(width: 8),
                if (!_loading)
                  Text('(${_filteredVoices.length} found)',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 11)),
              ],
            ),
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
          const SizedBox(height: 12),

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search voices…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
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

// ── AI Engine page ────────────────────────────────────────────────────────────

class _AiSourcePage extends StatelessWidget {
  const _AiSourcePage();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelProvider>();
    final tier = model.currentTier;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Engine')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Page intro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18,
                    color: cs.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choose how StoryTeller processes your books with AI. '
                    'Each option has different trade-offs between speed, '
                    'quality, and privacy.',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // On-device
          _SourceCard(
            title: 'On-Device AI',
            headline: 'Gemini Nano — runs entirely on your phone',
            description:
                'Your text never leaves your device. Uses Google\'s Gemini Nano '
                'model built into supported Android phones (Galaxy S24+ series, '
                'Pixel 9+). Processing is thorough but slower — expect a few '
                'seconds per page, especially for long texts.',
            tags: const [
              _Tag('🔒 Fully private', Colors.green),
              _Tag('📵 Works offline', Colors.blue),
              _Tag('⏳ Slower', Colors.orange),
              _Tag('Free forever', Colors.teal),
            ],
            icon: Icons.phone_android,
            selected: tier == SubscriptionTier.onDevice,
            onTap: () => model.switchTier(SubscriptionTier.onDevice),
            body: const _OnDevicePanel(),
          ),
          const SizedBox(height: 12),

          // Cloud AI
          _SourceCard(
            title: 'Cloud AI',
            headline: 'Google Gemini Flash — highest quality',
            description:
                'Processes text through Google\'s servers for the best reading '
                'experience. Translations are more natural, summaries are sharper, '
                'and responses are near-instant regardless of book length. '
                'Requires an internet connection and a subscription.',
            tags: const [
              _Tag('⚡ Very fast', Colors.blue),
              _Tag('✨ Best quality', Colors.purple),
              _Tag('🌐 Internet required', Colors.orange),
              _Tag('Subscription', Colors.grey),
            ],
            icon: Icons.cloud_outlined,
            selected: tier == SubscriptionTier.premium,
            onTap: () => model.switchTier(SubscriptionTier.premium),
            body: const _CloudPanel(),
          ),
          const SizedBox(height: 12),

          // BYOK
          _SourceCard(
            title: 'Own API Key',
            headline: 'Bring your Gemini or OpenAI key',
            description:
                'Full cloud AI quality with no monthly app subscription. '
                'You pay your AI provider directly (usually much cheaper for '
                'personal use). Requires an API key from Google AI Studio or '
                'OpenAI — takes about 2 minutes to set up.',
            tags: const [
              _Tag('⚡ Fast', Colors.blue),
              _Tag('✨ Full quality', Colors.purple),
              _Tag('💳 Pay-as-you-go', Colors.teal),
              _Tag('🌐 Internet required', Colors.orange),
            ],
            icon: Icons.key_outlined,
            selected: tier == SubscriptionTier.byok,
            onTap: () => model.switchTier(SubscriptionTier.byok),
            body: const _ByokPanel(),
          ),
          const SizedBox(height: 12),

          // Free
          _SourceCard(
            title: 'Free',
            headline: 'Limited daily AI requests — good for trying it out',
            description:
                'A small number of cloud AI calls per day at no cost. '
                'Great for exploring AI features before committing to a plan. '
                'When the daily limit is reached, books are read in the original '
                'language without AI processing.',
            tags: const [
              _Tag('🎁 No cost', Colors.green),
              _Tag('⚡ Fast', Colors.blue),
              _Tag('⚠️ Daily limit', Colors.orange),
              _Tag('🌐 Internet required', Colors.grey),
            ],
            icon: Icons.lock_open_outlined,
            selected: tier == SubscriptionTier.free,
            onTap: () => model.switchTier(SubscriptionTier.free),
          ),
        ],
      ),
    );
  }
}

/// A small label shown inside the feature-tag row of each source card.
class _Tag {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
}

class _SourceCard extends StatelessWidget {
  final String title;

  /// Bold one-liner shown directly under the title.
  final String headline;

  /// 2–3 sentence description shown when the card is selected.
  final String description;

  final List<_Tag> tags;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? body;

  const _SourceCard({
    required this.title,
    required this.headline,
    required this.description,
    required this.tags,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? cs.primary : cs.outline.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
        color: selected
            ? cs.primary.withValues(alpha: 0.04)
            : cs.surface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: icon + title + radio
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.onSurface.withValues(alpha: 0.06),
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: selected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: selected
                                    ? cs.primary
                                    : cs.onSurface)),
                        const SizedBox(height: 1),
                        Text(headline,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.3),
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Feature tags — always visible for quick scanning
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((t) => _buildTag(context, t)).toList(),
              ),

              // Description — only when selected
              if (selected) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.55),
                ),
              ],

              // Expanded panel (API key fields, download button, etc.)
              if (selected && body != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                body!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, _Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tag.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
            fontSize: 11,
            color: tag.color.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500),
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
  String _status = 'checking'; // checking | available | downloadable | downloading | unavailable
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _status = 'checking');
    try {
      final svc = context.read<ModelProvider>().modelManager.onDeviceService;
      svc.invalidateCache();
      final s = await svc.checkStatus();
      if (mounted) setState(() => _status = s);
    } catch (_) {
      if (mounted) setState(() => _status = 'unavailable');
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final svc = context.read<ModelProvider>().modelManager.onDeviceService;
      await svc.ensureDownloaded();
      await _check();
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_status == 'checking') {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_status == 'available') {
      return _InfoBox(
        color: Colors.green.shade700,
        icon: Icons.check_circle_outline,
        text: 'Gemini Nano is ready on this device. On-device AI is active.',
      );
    }
    if (_status == 'downloading') {
      return _InfoBox(
        color: cs.primary,
        icon: Icons.downloading_outlined,
        text: 'Gemini Nano is downloading in the background. This may take a few minutes.',
        trailing: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ),
      );
    }
    if (_status == 'downloadable') {
      return _InfoBox(
        color: Colors.orange.shade700,
        icon: Icons.cloud_download_outlined,
        text: 'Gemini Nano is available but needs to be downloaded (~1–2 GB).',
        trailing: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.icon(
            onPressed: _downloading ? null : _download,
            icon: _downloading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_for_offline_outlined, size: 18),
            label: const Text('Download Gemini Nano'),
          ),
        ),
      );
    }
    // unavailable
    return _InfoBox(
      color: Colors.red.shade700,
      icon: Icons.error_outline,
      text: 'On-device AI is not supported on this device, or Google AICore '
          'is not installed. Search "Google AI Core" on the Play Store.',
      trailing: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: _check,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Re-check'),
        ),
      ),
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
  final Widget? trailing;

  const _InfoBox({
    required this.color,
    required this.icon,
    required this.text,
    this.trailing,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
