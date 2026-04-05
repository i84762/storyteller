import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reader_provider.dart';
import '../providers/model_provider.dart';
import '../models/subscription_tier.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reader = context.watch<ReaderProvider>();
    final model = context.watch<ModelProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'StoryTeller',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.currentTier.displayName,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.tune, color: Colors.white70),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.workspace_premium,
                              color: Colors.amber),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/subscription'),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // Hero area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.deepPurple.shade400,
                              Colors.deepPurple.shade900,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Your AI Reading\nCompanion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Load a PDF and let AI read it to you.\nAsk questions. Navigate by voice.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tier indicator chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: SubscriptionTier.values.map((t) {
                    final isActive = t == model.currentTier;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isActive
                            ? Colors.deepPurple
                            : Colors.white.withOpacity(0.08),
                      ),
                      child: Text(
                        t.displayName.split(' ').first,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Open PDF button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Open PDF',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () => _openPdf(context, reader),
                ),
              ),

              if (reader.hasPdf) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.menu_book, color: Colors.white70),
                    label: const Text('Continue Reading',
                        style: TextStyle(color: Colors.white70)),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/reader'),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, ReaderProvider reader) async {
    final success = await reader.pickAndLoadPdf();
    if (!context.mounted) return;
    if (success) {
      Navigator.pushNamed(context, '/reader');
    } else if (reader.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reader.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: reader.clearError,
          ),
        ),
      );
      reader.clearError();
    }
  }
}
