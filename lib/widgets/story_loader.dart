import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A storytelling-themed animated loader.
///
/// Visual: an open book icon above five animated "text line" bars that wave
/// with staggered timing — like words appearing on a fresh page.
/// Respects the active app theme (sepia / dark-purple / system).
class StoryLoader extends StatefulWidget {
  final String? message;
  final double size;

  const StoryLoader({super.key, this.message, this.size = 80});

  @override
  State<StoryLoader> createState() => _StoryLoaderState();
}

class _StoryLoaderState extends State<StoryLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Each bar has a phase offset so they wave in sequence left-to-right.
  static const _barCount = 5;
  static const _barWidthFractions = [0.72, 0.88, 0.60, 0.80, 0.50];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barWidth = widget.size * 0.95;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Open book icon with soft glow ──────────────────────────────
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final glow = 0.5 + 0.5 * math.sin(_ctrl.value * 2 * math.pi);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12 + 0.12 * glow),
                    blurRadius: 18 + 8 * glow,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: widget.size * 0.52,
                color: cs.primary.withValues(alpha: 0.85 + 0.15 * glow),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Animated text-line bars ────────────────────────────────────
        SizedBox(
          width: barWidth,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_barCount, (i) {
                  // Each bar lags by 1/barCount of the total cycle.
                  final phase = i / _barCount;
                  final t = (_ctrl.value + phase) % 1.0;
                  // Sine wave: bar brightens then dims repeatedly.
                  final brightness =
                      0.18 + 0.55 * math.pow(math.sin(t * math.pi), 2);
                  final scaleX = 0.6 + 0.4 * math.pow(
                      math.sin((t + 0.15) * math.pi).clamp(0.0, 1.0), 1.5);
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < _barCount - 1 ? 7 : 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            _barWidthFractions[i] * scaleX,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: cs.primary.withValues(alpha: brightness),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),

        if (widget.message != null) ...[
          const SizedBox(height: 18),
          Text(
            widget.message!,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 13,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
