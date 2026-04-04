import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../providers/model_provider.dart';
import '../widgets/voice_input_button.dart';
import '../widgets/usage_indicator.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();

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
                  _StateChip(reader.state),
                ],
              ),
            ),

          // PDF text display
          Expanded(
            child: reader.hasPdf
                ? _PdfTextView(
                    text: reader.currentPageText,
                    isReading: reader.state == ReaderState.reading,
                  )
                : const _EmptyState(),
          ),

          // Conversation bubble
          if (reader.lastUserInput != null ||
              reader.lastAssistantResponse != null)
            _ConversationBubble(
              userText: reader.lastUserInput,
              assistantText: reader.lastAssistantResponse,
            ),

          // Controls
          _ControlBar(reader: reader),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 80, color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'No PDF loaded',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
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

class _ControlBar extends StatelessWidget {
  final ReaderProvider reader;
  const _ControlBar({required this.reader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white70),
            onPressed: reader.hasPdf ? reader.previousPage : null,
          ),
          IconButton(
            icon: const Icon(Icons.fast_rewind, color: Colors.white70),
            onPressed: reader.hasPdf ? reader.slowDown : null,
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
            icon: const Icon(Icons.fast_forward, color: Colors.white70),
            onPressed: reader.hasPdf ? reader.speedUp : null,
          ),
          IconButton(
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
