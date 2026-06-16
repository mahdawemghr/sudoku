import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/engine/hint_explainer.dart';
import 'package:sudoku/shared/widgets/glow_container.dart';

/// Non-blocking banner shown above the board explaining why a hint's
/// revealed value is correct. Swipe up or wait it out — gameplay keeps going.
class HintBanner extends StatelessWidget {
  final HintExplanation explanation;
  final VoidCallback onDismiss;

  const HintBanner({
    super.key,
    required this.explanation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dismissible(
      key: ValueKey(explanation),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: GlowContainer(
        glowColor: colors.accentPurple,
        backgroundColor: colors.surface,
        glowRadius: 10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded, color: colors.accentPurple, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    explanation.title,
                    style: TextStyle(
                      color: colors.accentPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    explanation.reason,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, color: colors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
