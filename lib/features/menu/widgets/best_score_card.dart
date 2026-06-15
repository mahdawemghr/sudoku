import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';
import 'package:sudoku/data/models/difficulty.dart';

class BestScoreCard extends StatelessWidget {
  final Difficulty difficulty;
  final int? bestTime;

  const BestScoreCard({
    super.key,
    required this.difficulty,
    required this.bestTime,
  });

  Color _difficultyColor(AppColorsExtension colors) {
    switch (difficulty) {
      case Difficulty.easy:
        return colors.secondaryNeon;
      case Difficulty.medium:
        return colors.primaryNeon;
      case Difficulty.hard:
        return colors.accentPurple;
      case Difficulty.impossible:
        return colors.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _difficultyColor(colors);
    final hasTime = bestTime != null;
    final timeLabel = hasTime ? DurationFormatter.format(bestTime!) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: hasTime ? 0.6 : 0.25),
          width: 1.5,
        ),
        boxShadow: hasTime
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            difficulty.displayName.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            timeLabel,
            style: TextStyle(
              color: hasTime ? colors.textPrimary : colors.textDisabled,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
