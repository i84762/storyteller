import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listening_mode.dart';
import '../models/reading_tone.dart';
import '../providers/reader_provider.dart';

/// Shows a bottom sheet for picking a [ListeningMode].
/// Call via [ListeningModePicker.show].
class ListeningModePicker extends StatelessWidget {
  const ListeningModePicker({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ReaderProvider>(),
        child: const ListeningModePicker(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.headphones, color: Colors.white70),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Listening Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (reader.listeningMode.isAiPowered)
                  _AiBadge(label: reader.listeningMode.displayName),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Mode list
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Tone section ─────────────────────────────────────────
                _ToneSection(
                  selectedTone: reader.tone,
                  suggestedTone: ReadingToneX.defaultFor(reader.listeningMode),
                  onToneSelected: (t) => reader.setTone(t),
                ),
                const SizedBox(height: 4),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 4),
                ...ListeningMode.values.map((mode) {
                  return _ModeCard(
                    mode: mode,
                    isSelected: reader.listeningMode == mode,
                    onTap: () => _onSelect(context, mode, reader),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelect(
    BuildContext context,
    ListeningMode mode,
    ReaderProvider reader,
  ) async {
    if (mode.requiresTopic) {
      final topic = await _promptForTopic(context, reader.focusTopic);
      if (topic == null) return; // user cancelled
      reader.setListeningMode(mode, focusTopic: topic);
    } else {
      reader.setListeningMode(mode);
    }

    if (context.mounted) Navigator.pop(context);

    // If already reading, restart the current page with the new mode.
    if (reader.state == ReaderState.reading) {
      await reader.stop();
      await reader.startReading();
    }
  }

  Future<String?> _promptForTopic(
      BuildContext context, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('What would you like to focus on?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. The role of Parliament',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.deepPurpleAccent),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Set Focus'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final ListeningMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = mode.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.white12,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(mode.icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Text(
              mode.displayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            if (mode.isAiPowered) ...[
              const SizedBox(width: 8),
              _AiBadge(label: 'AI'),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            mode.description,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : null,
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  final String label;
  const _AiBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label == 'AI' ? '✦ AI' : '✦ AI',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ToneSection extends StatelessWidget {
  final ReadingTone selectedTone;
  final ReadingTone suggestedTone;
  final ValueChanged<ReadingTone> onToneSelected;

  const _ToneSection({
    required this.selectedTone,
    required this.suggestedTone,
    required this.onToneSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              const Text(
                'Tone',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${selectedTone.emoji} ${selectedTone.displayName}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: ReadingTone.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final tone = ReadingTone.values[i];
              final isSelected = tone == selectedTone;
              final isSuggested = tone == suggestedTone;
              return GestureDetector(
                onTap: () => onToneSelected(tone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurpleAccent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurpleAccent
                          : isSuggested
                              ? Colors.deepPurpleAccent.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tone.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        tone.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.deepPurpleAccent
                              : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                      if (isSuggested && !isSelected) ...[
                        const SizedBox(width: 4),
                        const Text('✨', style: TextStyle(fontSize: 9)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
