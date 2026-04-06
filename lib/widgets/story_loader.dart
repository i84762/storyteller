import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A storytelling-themed animated loader.
/// Shows an open book with animated turning pages and floating sparkles.
/// Respects the active app theme (sepia / dark-purple / system).
class StoryLoader extends StatefulWidget {
  final String? message;
  final double size;

  const StoryLoader({super.key, this.message, this.size = 80});

  @override
  State<StoryLoader> createState() => _StoryLoaderState();
}

class _StoryLoaderState extends State<StoryLoader>
    with TickerProviderStateMixin {
  late final AnimationController _pageCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: false);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _glowCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary
                            .withValues(alpha: 0.1 + 0.15 * _glowCtrl.value),
                        blurRadius: 20 + 10 * _glowCtrl.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Book icon base
              Icon(
                Icons.menu_book_rounded,
                size: widget.size * 0.55,
                color: cs.primary.withValues(alpha: 0.9),
              ),

              // Animated turning page
              AnimatedBuilder(
                animation: _pageCtrl,
                builder: (_, __) {
                  final angle = _pageCtrl.value * math.pi;
                  final isFlipped = _pageCtrl.value > 0.5;
                  final pageColor = isFlipped
                      ? cs.primaryContainer
                      : cs.secondaryContainer;
                  return Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(angle),
                    child: Container(
                      width: widget.size * 0.22,
                      height: widget.size * 0.30,
                      margin: EdgeInsets.only(left: widget.size * 0.02),
                      decoration: BoxDecoration(
                        color: pageColor.withValues(alpha: 0.85),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Floating sparkles
              ..._buildSparkles(cs),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.message!,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSparkles(ColorScheme cs) {
    const sparklePositions = [
      Offset(-0.38, -0.38),
      Offset(0.40, -0.32),
      Offset(-0.42, 0.28),
      Offset(0.38, 0.36),
    ];
    return sparklePositions.asMap().entries.map((e) {
      final offset = e.value;
      final phase = e.key / sparklePositions.length;
      return AnimatedBuilder(
        animation: _sparkleCtrl,
        builder: (_, __) {
          final t = (_sparkleCtrl.value + phase) % 1.0;
          final opacity = math.sin(t * math.pi).clamp(0.0, 1.0);
          final scale = 0.5 + 0.5 * math.sin(t * math.pi);
          return Positioned(
            left: widget.size / 2 + offset.dx * widget.size / 2 - 6,
            top: widget.size / 2 + offset.dy * widget.size / 2 - 6,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.auto_awesome,
                  size: 10,
                  color: cs.tertiary,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}
