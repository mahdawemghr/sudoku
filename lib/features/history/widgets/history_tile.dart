import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/date_formatter.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';

class HistoryTile extends StatelessWidget {
  final GameRecord record;

  const HistoryTile({super.key, required this.record});

  Color _difficultyColor(AppColorsExtension colors) {
    switch (record.difficulty) {
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.format(record.completedAt),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.won ? 'Won' : 'Lost',
                  style: TextStyle(
                    color: record.won
                        ? colors.secondaryNeon
                        : colors.errorRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DurationFormatter.format(record.durationSeconds),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${record.mistakes} mistake${record.mistakes == 1 ? '' : 's'}',
                style: TextStyle(
                  color: colors.textSecondary,
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
