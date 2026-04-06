import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listening_mode.dart';
import '../models/reading_tone.dart';
import '../providers/reader_provider.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/listening_mode_picker.dart';
import '../widgets/story_loader.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String? _lastShownError;

  /// When true, shows the raw PDF text instead of the AI-processed version.
  bool _showOriginal = false;

  /// Track page/mode so we can reset the toggle when they change.
  int _toggleResetPage = -1;
  ListeningMode? _toggleResetMode;

  /// Resets the original-view toggle whenever the page or mode changes.
  void _maybeResetToggle(ReaderProvider reader) {
    if (reader.currentPage != _toggleResetPage ||
        reader.listeningMode != _toggleResetMode) {
      _toggleResetPage = reader.currentPage;
      _toggleResetMode = reader.listeningMode;
      if (_showOriginal) {
        // Use addPostFrameCallback to avoid setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showOriginal = false);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show snackbar whenever a new AI error arrives.
    final error = context.read<ReaderProvider>().aiError;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReaderProvider>().clearAiError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF16213E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    _maybeResetToggle(reader);
    final error = reader.aiError;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        reader.clearAiError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF16213E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reader.pdfPath?.split(RegExp(r'[/\\]')).last
                  .replaceAll('.pdf', '') ?? 'StoryTeller',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (reader.hasPdf)
              Text(
                'Page ${reader.currentPage + 1} of ${reader.totalPages}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
        actions: [
          if (reader.hasPdf) ...[
            // Mode chip in AppBar actions
            GestureDetector(
              onTap: () => ListeningModePicker.show(context),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reader.listeningMode.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: reader.listeningMode.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(reader.listeningMode.icon,
                        size: 12, color: reader.listeningMode.color),
                    const SizedBox(width: 4),
                    Text(
                      reader.listeningMode.shortName,
                      style: TextStyle(
                        color: reader.listeningMode.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            visualDensity: VisualDensity.compact,
          ),
          if (reader.hasPdf && !reader.isProcessingOffline)
            GestureDetector(
              onTap: () => _showOfflineDialog(context, reader),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFB45FEC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // AI-processing indicator
          if (reader.isTranslating)
            Builder(builder: (ctx) {
              final cs = Theme.of(ctx).colorScheme;
              final chunk = reader.processingChunk;
              final total = reader.totalChunks;
              final label = total > 1
                  ? 'Processing part ${chunk + 1} of $total…'
                  : reader.listeningMode == ListeningMode.wordToWord
                      ? 'Translating…'
                      : 'Processing with AI…';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: cs.primaryContainer.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                        value: total > 1 ? chunk / total : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(label,
                        style: TextStyle(color: cs.primary, fontSize: 12)),
                  ],
                ),
              );
            }),

          // Offline-processing progress banner
          if (reader.isProcessingOffline)
            Builder(builder: (ctx) {
              final done = reader.offlineProgress;
              final total = reader.offlineTotal;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.orange.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                        value: total > 0 ? done / total : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Processing offline: $done / $total pages',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: reader.cancelOfflineProcessing,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.orange,
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              );
            }),

          // PDF text display
          Expanded(
            child: reader.hasPdf
                ? _buildTextView(reader)
                : const _EmptyState(),
          ),

          // ── Original / AI toggle ─────────────────────────────────────────
          // Shown only when AI text is ready — lets the user peek at the
          // source PDF while still listening to the AI-processed audio.
          if (reader.hasPdf &&
              reader.listeningMode.isAiPowered &&
              !reader.pictorialEnabled &&
              reader.wordSpans.isNotEmpty)
            _OriginalToggleBar(
              showOriginal: _showOriginal,
              onToggle: (v) => setState(() => _showOriginal = v),
            ),

          // Conversation bubble
          if (reader.lastUserInput != null ||
              reader.lastAssistantResponse != null)
            _ConversationBubble(
              userText: reader.lastUserInput,
              assistantText: reader.lastAssistantResponse,
            ),

          // ── Bottom player panel ──────────────────────────────────────────
          if (reader.hasPdf) _BottomPlayer(reader: reader),
        ],
      ),
    );
  }

  Future<void> _showOfflineDialog(
      BuildContext context, ReaderProvider reader) async {
    ListeningMode selectedMode = reader.listeningMode;
    ReadingTone selectedTone = reader.tone;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('Process for Offline'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pre-process all pages so the book reads offline without live AI.',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _ConfigRow(
                    label: 'Mode',
                    child: DropdownButton<ListeningMode>(
                      value: selectedMode,
                      isDense: true,
                      onChanged: (v) {
                        if (v != null) setLocalState(() => selectedMode = v);
                      },
                      items: ListeningMode.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.displayName,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ConfigRow(
                    label: 'Tone',
                    child: DropdownButton<ReadingTone>(
                      value: selectedTone,
                      isDense: true,
                      onChanged: (v) {
                        if (v != null) setLocalState(() => selectedTone = v);
                      },
                      items: ReadingTone.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                    '${t.emoji} ${t.displayName}',
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    reader.processForOffline(
                        mode: selectedMode, tone: selectedTone);
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextView(ReaderProvider reader) {
    // Show thematic loader while raw page text is being fetched from disk.
    if (reader.isLoadingPage) {
      return Center(
        child: StoryLoader(message: 'Turning the page…'),
      );
    }

    if (reader.pictorialEnabled) {
      return _PictorialView(
        key: ValueKey('pic_${reader.currentPage}'),
        image: reader.currentPageImage,
        isGenerating: reader.isGeneratingImage,
        wordSpans: reader.wordSpans,
        currentWordIndex: reader.currentWordIndex,
        onWordTap: reader.jumpToWord,
        showSubtitles: reader.pictorialSubtitles,
      );
    }

    final isReading = reader.state == ReaderState.reading;

    // Only highlight words when the screen is showing the same text that
    // TTS is speaking. If the user has switched to the original PDF view,
    // the character offsets in wordSpans don't match the raw text, so
    // highlighting is suppressed to avoid misleading jumps.
    final canHighlight = reader.wordSpans.isNotEmpty && !_showOriginal;

    if (canHighlight) {
      return _WordHighlightView(
        key: ValueKey(reader.currentPage),
        fullText: reader.spokenText,
        wordSpans: reader.wordSpans,
        currentWordIndex: reader.currentWordIndex,
        onWordTap: reader.jumpToWord,
      );
    }

    final text = _showOriginal
        ? reader.currentPageText
        : (reader.displayText.isEmpty ? reader.currentPageText : reader.displayText);

    return _PdfTextView(text: text, isReading: isReading);
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _ConfigRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

// ── Word highlight view ───────────────────────────────────────────────────────

class _WordHighlightView extends StatefulWidget {
  final String fullText;
  final List<WordSpan> wordSpans;
  final int currentWordIndex;
  final void Function(int) onWordTap;

  const _WordHighlightView({
    super.key,
    required this.fullText,
    required this.wordSpans,
    required this.currentWordIndex,
    required this.onWordTap,
  });

  @override
  State<_WordHighlightView> createState() => _WordHighlightViewState();
}

class _WordHighlightViewState extends State<_WordHighlightView> {
  final ScrollController _scroll = ScrollController();
  List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _buildRecognizers();
  }

  @override
  void didUpdateWidget(_WordHighlightView old) {
    super.didUpdateWidget(old);
    if (widget.fullText != old.fullText) {
      _disposeRecognizers();
      _buildRecognizers();
    }
    if (widget.currentWordIndex != old.currentWordIndex &&
        widget.currentWordIndex >= 0) {
      _scrollToWord(widget.currentWordIndex);
    }
  }

  void _buildRecognizers() {
    _recognizers = List.generate(
      widget.wordSpans.length,
      (i) => TapGestureRecognizer()..onTap = () => widget.onWordTap(i),
    );
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
  }

  void _scrollToWord(int idx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || widget.wordSpans.isEmpty) return;
      final progress = idx / widget.wordSpans.length;
      final target =
          (_scroll.position.maxScrollExtent * progress).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _disposeRecognizers();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = cs.brightness == Brightness.light;
    final text = widget.fullText;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    const fontSize = 16.0;
    const lineHeight = 1.8;
    const fontFamily = 'Georgia';

    final baseStyle = TextStyle(
      color: cs.onSurface,
      fontSize: fontSize,
      height: lineHeight,
      fontFamily: fontFamily,
    );

    // Theme-matched highlight:
    //
    // Sepia (light): the active word shifts to the warm sienna primary colour
    // with a barely-there warm wash behind it — like ink catching the reading
    // lamp. No harsh contrast, no foreign colours.
    //
    // Dark Purple: the word brightens to the vivid lavender accent
    // (onPrimaryContainer) with a soft lavender background tint and a gentle
    // radial glow via Shadow — like a word quietly illuminating itself.
    final highlightStyle = isLight
        ? TextStyle(
            color: cs.primary,
            backgroundColor: cs.primary.withAlpha(22),
            fontSize: fontSize,
            height: lineHeight,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          )
        : TextStyle(
            color: cs.onPrimaryContainer,
            backgroundColor: cs.primary.withAlpha(38),
            fontSize: fontSize,
            height: lineHeight,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: cs.primary.withAlpha(115),
                blurRadius: 14,
              ),
            ],
          );

    for (int i = 0; i < widget.wordSpans.length; i++) {
      final span = widget.wordSpans[i];

      // Whitespace / punctuation before this word
      if (span.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, span.start),
          style: baseStyle,
        ));
      }

      final isHighlighted = i == widget.currentWordIndex;
      spans.add(TextSpan(
        text: span.text,
        style: isHighlighted ? highlightStyle : baseStyle,
        recognizer: _recognizers[i],
      ));
      lastEnd = span.end;
    }

    // Any trailing text after the last word
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.all(20),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}

// ── Pictorial mode view ───────────────────────────────────────────────────────

class _PictorialView extends StatelessWidget {
  final Uint8List? image;
  final bool isGenerating;
  final List<WordSpan> wordSpans;
  final int currentWordIndex;
  final void Function(int) onWordTap;
  final bool showSubtitles;

  const _PictorialView({
    super.key,
    required this.image,
    required this.isGenerating,
    required this.wordSpans,
    required this.currentWordIndex,
    required this.onWordTap,
    required this.showSubtitles,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: image or themed loader ────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: image != null
                ? Image.memory(
                    image!,
                    key: ValueKey(image.hashCode),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                  )
                : Container(
                    key: const ValueKey('loader'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primaryContainer.withValues(alpha: 0.6),
                          cs.secondaryContainer.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: StoryLoader(
                        message: 'Illustrating your story…',
                        size: 100,
                      ),
                    ),
                  ),
          ),

          // ── Top vignette ───────────────────────────────────────────────
          if (image != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom gradient + subtitles ────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: image != null
                      ? [Colors.transparent, Colors.black.withValues(alpha: 0.85)]
                      : [Colors.transparent, cs.surface.withValues(alpha: 0.7)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
              child: showSubtitles && wordSpans.isNotEmpty && currentWordIndex >= 0
                  ? _CurrentWordDisplay(
                      wordSpans: wordSpans,
                      currentWordIndex: currentWordIndex,
                      onWordTap: onWordTap,
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // ── Generating badge (only while loading next image) ──────────
          if (isGenerating && image != null)
            Positioned(
              top: 14,
              right: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.primary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        '✦ Illustrating…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PictorialShimmer extends StatefulWidget {
  const _PictorialShimmer({super.key});
  @override
  State<_PictorialShimmer> createState() => _PictorialShimmerState();
}

class _PictorialShimmerState extends State<_PictorialShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: Color.lerp(
          cs.surfaceContainerHighest,
          cs.primaryContainer,
          _anim.value,
        ),
        child: Center(
          child: Icon(Icons.auto_awesome,
              size: 48,
              color: cs.primary.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

/// Shows the current spoken word prominently at the bottom of the pictorial view.
class _CurrentWordDisplay extends StatelessWidget {
  final List<WordSpan> wordSpans;
  final int currentWordIndex;
  final void Function(int) onWordTap;

  const _CurrentWordDisplay({
    required this.wordSpans,
    required this.currentWordIndex,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show a small sliding window: 2 words before, current, 2 after
    final start = (currentWordIndex - 2).clamp(0, wordSpans.length - 1);
    final end = (currentWordIndex + 3).clamp(0, wordSpans.length);
    final visible = wordSpans.sublist(start, end);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: visible.map((span) {
        final idx = wordSpans.indexOf(span);
        final isCurrent = idx == currentWordIndex;
        return GestureDetector(
          onTap: () => onWordTap(idx),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white60,
              fontSize: isCurrent ? 22 : 16,
              fontWeight:
                  isCurrent ? FontWeight.bold : FontWeight.normal,
              shadows: isCurrent
                  ? [
                      const Shadow(
                          color: Colors.black, blurRadius: 8)
                    ]
                  : null,
            ),
            child: Text(span.text),
          ),
        );
      }).toList(),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

/// Compact toggle bar that lets the user flip between AI-processed text and
/// the original PDF source. Only rendered when AI text is ready.
class _OriginalToggleBar extends StatelessWidget {
  final bool showOriginal;
  final ValueChanged<bool> onToggle;

  const _OriginalToggleBar({
    required this.showOriginal,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(Icons.swap_horiz,
              size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            'Viewing:',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: '✦ AI Text',
            selected: !showOriginal,
            onTap: () => onToggle(false),
          ),
          const SizedBox(width: 6),
          _ToggleChip(
            label: '📄 Original',
            selected: showOriginal,
            onTap: () => onToggle(true),
          ),
          if (showOriginal) ...[
            const SizedBox(width: 8),
            Icon(Icons.highlight_off,
                size: 12, color: cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(width: 3),
            Text(
              'Highlighting paused',
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _PdfTextView extends StatelessWidget {
  final String text;
  final bool isReading;

  const _PdfTextView({required this.text, required this.isReading});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedOpacity(
        opacity: isReading ? 1.0 : 0.75,
        duration: const Duration(milliseconds: 300),
        child: Text(
          text.isEmpty ? 'This page has no text content.' : text,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 16,
            height: 1.7,
            fontFamily: 'Georgia',
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80,
              color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text(
            'No PDF loaded',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to open a PDF',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final String? userText;
  final String? assistantText;

  const _ConversationBubble({this.userText, this.assistantText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (userText != null)
            Row(
              children: [
                Icon(Icons.person, size: 14,
                    color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(userText!,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 13)),
                ),
              ],
            ),
          if (userText != null && assistantText != null)
            const SizedBox(height: 6),
          if (assistantText != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(assistantText!,
                      style: TextStyle(
                          color: cs.onSurface, fontSize: 13)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Unified bottom player panel.
///
/// Layout (top → bottom):
///   1. Thin page-progress bar
///   2. Controls row: prev | slow | play/pause | fast | next | mic
///   3. Speed pill + SafeArea bottom padding
class _BottomPlayer extends StatelessWidget {
  final ReaderProvider reader;
  const _BottomPlayer({required this.reader});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isReading = reader.state == ReaderState.reading;
    final rate = reader.speechRate;
    final displayRate = rate / 0.5;
    final atMin = rate <= 0.25;
    final atMax = rate >= 1.5;
    final progress = reader.totalPages > 0
        ? (reader.currentPage + 1) / reader.totalPages
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page progress bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),

            // Controls row: speed− | prev | play/pause | next | speed+
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Slow down (−) — tertiary, compact
                  _SpeedButton(
                    icon: Icons.remove_rounded,
                    enabled: !atMin,
                    onTap: reader.slowDown,
                  ),

                  // Previous page — secondary, prominent
                  _NavButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Previous page',
                    enabled: reader.hasPdf && reader.currentPage > 0,
                    onTap: reader.previousPage,
                    cs: cs,
                  ),

                  // Play / Pause — primary
                  GestureDetector(
                    onTap: reader.hasPdf
                        ? () {
                            if (isReading) {
                              reader.pause();
                            } else {
                              reader.startReading();
                            }
                          }
                        : null,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: reader.hasPdf
                            ? LinearGradient(
                                colors: [
                                  cs.primary,
                                  cs.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: reader.hasPdf
                            ? null
                            : cs.onSurface.withValues(alpha: 0.12),
                        boxShadow: reader.hasPdf
                            ? [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        isReading ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: reader.hasPdf
                            ? cs.onPrimary
                            : cs.onSurface.withValues(alpha: 0.3),
                        size: 30,
                      ),
                    ),
                  ),

                  // Next page — secondary, prominent
                  _NavButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next page',
                    enabled: reader.hasPdf &&
                        reader.currentPage < reader.totalPages - 1,
                    onTap: reader.nextPage,
                    cs: cs,
                  ),

                  // Speed up (+) — tertiary, compact
                  _SpeedButton(
                    icon: Icons.add_rounded,
                    enabled: !atMax,
                    onTap: reader.speedUp,
                  ),
                ],
              ),
            ),

            // Bottom row: mic + speed label
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VoiceInputButton(),
                  const SizedBox(width: 16),
                  Text(
                    '${displayRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large navigation button (prev/next page) — prominently sized.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? cs.onSurface.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled
                ? cs.onSurface.withValues(alpha: 0.85)
                : cs.onSurface.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

/// Small speed control button (+/−) — compact tertiary control.
class _SpeedButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? cs.onSurface.withValues(alpha: 0.55)
              : cs.onSurface.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

