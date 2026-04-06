import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../providers/model_provider.dart';

class VoiceInputButton extends StatelessWidget {
  /// When [compact] is true renders as a 40×40 icon button without glow,
  /// suitable for the player control bar.
  final bool compact;
  const VoiceInputButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final model = context.watch<ModelProvider>();

    final isListening = reader.state == ReaderState.listening;
    final isProcessing = model.isLoading;

    final double size = compact ? 40 : 72;
    final double iconSize = compact ? 20 : 32;

    return GestureDetector(
      onTap: isProcessing ? null : () => _handleVoiceInput(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? Colors.red.withValues(alpha: compact ? 0.15 : 1.0)
              : isProcessing
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                  : compact
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.primary,
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: (isListening ? Colors.red : Colors.deepPurple)
                        .withOpacity(0.4),
                    blurRadius: isListening ? 20 : 8,
                    spreadRadius: isListening ? 4 : 0,
                  )
                ],
        ),
        child: Center(
          child: isListening
              ? compact
                  ? Icon(Icons.mic, color: Colors.red, size: iconSize)
                  : SpinKitPulse(color: Colors.white, size: iconSize)
              : isProcessing
                  ? SpinKitThreeBounce(
                      color: compact
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                          : Colors.white,
                      size: compact ? 12 : 16)
                  : Icon(
                      Icons.mic,
                      color: compact
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white,
                      size: iconSize,
                    ),
        ),
      ),
    );
  }

  Future<void> _handleVoiceInput(BuildContext context) async {
    final reader = context.read<ReaderProvider>();
    final modelProvider = context.read<ModelProvider>();

    // Pause reading before listening
    if (reader.state == ReaderState.reading) {
      await reader.pause();
    }

    final spokenInput = await reader.listenToUser();
    if (spokenInput == null || spokenInput.isEmpty) {
      await reader.resume();
      return;
    }

    final response = await modelProvider.processUserInput(
      spokenInput: spokenInput,
      pdfContext: reader.currentPdfContext,
    );

    if (response != null) {
      await reader.speakResponse(response);
    } else {
      // Handle errors
      final error = modelProvider.error;
      if (!context.mounted) return;
      if (error == 'free_limit_reached') {
        _showSubscriptionPopup(context);
      } else if (error == 'missing_api_key') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please configure your API key in settings.')),
        );
      }
    }
  }

  void _showSubscriptionPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const SubscriptionPopupDialog(),
    );
  }
}

class SubscriptionPopupDialog extends StatelessWidget {
  const SubscriptionPopupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber),
          SizedBox(width: 8),
          Text('Upgrade StoryTeller'),
        ],
      ),
      content: const Text(
        'You\'ve reached your daily free limit.\n\nUpgrade to Premium for unlimited reading, or bring your own API key.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/subscription');
          },
          child: const Text('View Plans'),
        ),
      ],
    );
  }
}
