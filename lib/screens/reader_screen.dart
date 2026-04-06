import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/listening_mode.dart';
import '../providers/reader_provider.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/listening_mode_picker.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  String? _lastShownError;

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

    // Re-check for new errors after every rebuild.
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

          // PDF text display
          Expanded(
            child: reader.hasPdf
                ? _buildTextView(reader)
                : const _EmptyState(),
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

  Widget _buildTextView(ReaderProvider reader) {
    final isReading = reader.state == ReaderState.reading;

    // Use the interactive word-highlight view whenever word spans are
    // available — this works for every AI mode, not just word-to-word.
    if (reader.wordSpans.isNotEmpty) {
      return _WordHighlightView(
        key: ValueKey(reader.currentPage),
        fullText: reader.spokenText,
        wordSpans: reader.wordSpans,
        currentWordIndex: reader.currentWordIndex,
        onWordTap: reader.jumpToWord,
      );
    }

    return _PdfTextView(
      text: reader.displayText.isEmpty
          ? reader.currentPageText
          : reader.displayText,
      isReading: isReading,
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

// ── Supporting widgets ────────────────────────────────────────────────────────

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

            // Controls row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous page
                  IconButton(
                    tooltip: 'Previous page',
                    icon: Icon(Icons.skip_previous,
                        color: cs.onSurface.withValues(alpha: 0.7)),
                    iconSize: 26,
                    onPressed: reader.hasPdf && reader.currentPage > 0
                        ? reader.previousPage
                        : null,
                  ),

                  // Slow down
                  _SmallControlButton(
                    icon: Icons.remove,
                    label: 'Slow',
                    enabled: !atMin,
                    onTap: reader.slowDown,
                  ),

                  // Play / Pause
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
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reader.hasPdf
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        isReading ? Icons.pause : Icons.play_arrow,
                        color:
                            reader.hasPdf ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.3),
                        size: 28,
                      ),
                    ),
                  ),

                  // Speed up
                  _SmallControlButton(
                    icon: Icons.add,
                    label: 'Fast',
                    enabled: !atMax,
                    onTap: reader.speedUp,
                  ),

                  // Next page
                  IconButton(
                    tooltip: 'Next page',
                    icon: Icon(Icons.skip_next,
                        color: cs.onSurface.withValues(alpha: 0.7)),
                    iconSize: 26,
                    onPressed:
                        reader.hasPdf && reader.currentPage < reader.totalPages - 1
                            ? reader.nextPage
                            : null,
                  ),

                  // Mic
                  const VoiceInputButton(),
                ],
              ),
            ),

            // Speed pill
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${displayRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _SmallControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? cs.onSurface.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? cs.onSurface
                : cs.onSurface.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

