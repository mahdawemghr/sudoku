import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/date_formatter.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';

class HistoryTile extends StatelessWidget {
  final GameRecord record;

  const HistoryTile({super.key, required this.record});

  Color get _difficultyColor {
    switch (record.difficulty) {
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              record.difficulty.displayName.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Middle: date + outcome
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.format(record.completedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.won ? 'Won' : 'Lost',
                  style: TextStyle(
                    color: record.won
                        ? AppColors.secondaryNeon
                        : AppColors.errorRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Right: time + mistakes
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DurationFormatter.format(record.durationSeconds),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${record.mistakes} mistake${record.mistakes == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
