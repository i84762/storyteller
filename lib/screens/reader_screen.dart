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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: Text(
          reader.pdfPath?.split(RegExp(r'[/\\]')).last ?? 'StoryTeller',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(32),
          child: UsageIndicator(),
        ),
      ),
      body: Column(
        children: [
          // Page info bar
          if (reader.hasPdf)
            Container(
              color: const Color(0xFF16213E),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${reader.currentPage + 1} of ${reader.totalPages}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  // Mode chip — tap to change
                  GestureDetector(
                    onTap: () => ListeningModePicker.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: reader.listeningMode.color
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: reader.listeningMode.color
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(reader.listeningMode.icon,
                              size: 12,
                              color: reader.listeningMode.color),
                          const SizedBox(width: 4),
                          Text(
                            reader.listeningMode.displayName,
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
                  _StateChip(reader.state),
                ],
              ),
            ),

          // AI-processing indicator
          if (reader.isTranslating)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.deepPurple.withValues(alpha: 0.25),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    reader.listeningMode == ListeningMode.wordToWord
                        ? 'Translating…'
                        : 'Processing with AI…',
                    style: const TextStyle(
                        color: Colors.deepPurpleAccent, fontSize: 12),
                  ),
                ],
              ),
            ),

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

          // Speed control bar — only shown when a PDF is loaded
          if (reader.hasPdf) _SpeedBar(reader: reader),

          // Controls — SafeArea keeps them above the system navigation bar
          SafeArea(
            top: false,
            child: _ControlBar(reader: reader),
          ),
        ],
      ),
    );
  }

  Widget _buildTextView(ReaderProvider reader) {
    final isWordToWord = reader.listeningMode == ListeningMode.wordToWord;
    final isReading = reader.state == ReaderState.reading;

    // In word-to-word mode with word spans available, use the interactive
    // word-highlight view. Fall back to plain text view otherwise.
    if (isWordToWord && reader.wordSpans.isNotEmpty) {
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
    final text = widget.fullText;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    const normalStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      height: 1.8,
      fontFamily: 'Georgia',
    );
    const spaceStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      height: 1.8,
      fontFamily: 'Georgia',
    );

    for (int i = 0; i < widget.wordSpans.length; i++) {
      final span = widget.wordSpans[i];

      // Whitespace / punctuation before this word
      if (span.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, span.start),
          style: spaceStyle,
        ));
      }

      final isHighlighted = i == widget.currentWordIndex;
      spans.add(TextSpan(
        text: span.text,
        style: isHighlighted
            ? const TextStyle(
                color: Colors.black,
                backgroundColor: Color(0xFFFFD54F), // amber highlight
                fontSize: 16,
                height: 1.8,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w600,
              )
            : normalStyle,
        recognizer: _recognizers[i],
      ));
      lastEnd = span.end;
    }

    // Any trailing text after the last word
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: spaceStyle));
    }

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.all(20),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StateChip extends StatelessWidget {
  final ReaderState state;
  const _StateChip(this.state);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (state) {
      case ReaderState.reading:
        color = Colors.green;
        label = '● Reading';
        break;
      case ReaderState.listening:
        color = Colors.red;
        label = '● Listening';
        break;
      case ReaderState.paused:
        color = Colors.orange;
        label = '⏸ Paused';
        break;
      case ReaderState.loading:
        color = Colors.blue;
        label = '⟳ Loading';
        break;
      default:
        color = Colors.grey;
        label = '○ Idle';
    }
    return Text(label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600));
  }
}

class _PdfTextView extends StatelessWidget {
  final String text;
  final bool isReading;

  const _PdfTextView({required this.text, required this.isReading});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimatedOpacity(
        opacity: isReading ? 1.0 : 0.75,
        duration: const Duration(milliseconds: 300),
        child: Text(
          text.isEmpty ? 'This page has no text content.' : text,
          style: const TextStyle(
            color: Colors.white,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.white24),
          SizedBox(height: 20),
          Text(
            'No PDF loaded',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the button below to open a PDF',
            style: TextStyle(color: Colors.white30, fontSize: 14),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (userText != null)
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(userText!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SpeedBar extends StatelessWidget {
  final ReaderProvider reader;
  const _SpeedBar({required this.reader});

  @override
  Widget build(BuildContext context) {
    final rate = reader.speechRate;
    final atMin = rate <= 0.25;
    final atMax = rate >= 3.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.speed, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          _SpeedButton(
            icon: Icons.remove,
            enabled: !atMin,
            onTap: reader.slowDown,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 52,
            child: Text(
              '${rate.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}×',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _SpeedButton(
            icon: Icons.add,
            enabled: !atMax,
            onTap: reader.speedUp,
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _SpeedButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final ReaderProvider reader;
  const _ControlBar({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.skip_previous, color: Colors.white70),
            onPressed: reader.hasPdf ? reader.previousPage : null,
          ),

          // Main play/pause
          GestureDetector(
            onTap: reader.hasPdf ? _togglePlayPause(context, reader) : null,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.shade600,
              ),
              child: Icon(
                reader.state == ReaderState.reading
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          // Mic / voice button
          const VoiceInputButton(),

          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.skip_next, color: Colors.white70),
            onPressed: reader.hasPdf ? reader.nextPage : null,
          ),
        ],
      ),
    );
  }

  VoidCallback? _togglePlayPause(BuildContext context, ReaderProvider reader) {
    return () {
      if (reader.state == ReaderState.reading) {
        reader.pause();
      } else {
        reader.startReading();
      }
    };
  }
}
