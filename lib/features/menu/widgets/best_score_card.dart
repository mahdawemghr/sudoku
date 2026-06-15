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

  Color get _difficultyColor {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.secondaryNeon;
      case Difficulty.medium:
        return AppColors.primaryNeon;
      case Difficulty.hard:
        return AppColors.accentPurple;
      case Difficulty.impossible:
        return AppColors.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor;
    final timeLabel =
        bestTime != null ? DurationFormatter.format(bestTime!) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
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
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
