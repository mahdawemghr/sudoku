import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/constants/app_constants.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Lives
          Row(
            children: List.generate(AppConstants.maxLives, (i) {
              final filled = i < gameState.livesLeft;
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled
                      ? AppColors.errorRed
                      : AppColors.textDisabled,
                  size: 22,
                ),
              );
            }),
          ),

          // Timer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              DurationFormatter.format(gameState.elapsedSeconds),
              style: const TextStyle(
                color: AppColors.primaryNeon,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Hints
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${gameState.hintsLeft}',
                  style: const TextStyle(
                    color: AppColors.accentPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
