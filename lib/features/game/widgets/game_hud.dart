import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // Lives
          Expanded(
            child: _LivesRow(
              total: gameState.difficulty.maxLives,
              remaining: gameState.livesLeft,
              colors: colors,
            ),
          ),

          // Timer — always centered
          _TimerPill(
            seconds: gameState.elapsedSeconds,
            colors: colors,
          ),

          // Hints
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _HintPill(
                hintsLeft: gameState.hintsLeft,
                colors: colors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivesRow extends StatelessWidget {
  final int total;
  final int remaining;
  final AppColorsExtension colors;

  const _LivesRow({
    required this.total,
    required this.remaining,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < remaining;
        return Padding(
          padding: const EdgeInsets.only(right: 5.0),
          child: Container(
            decoration: filled
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.errorRed.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: Icon(
              filled ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: filled
                  ? colors.errorRed
                  : colors.textDisabled.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final int seconds;
  final AppColorsExtension colors;

  const _TimerPill({required this.seconds, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primaryNeon.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryNeon.withValues(alpha: 0.18),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: colors.primaryNeon.withValues(alpha: 0.8),
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            DurationFormatter.format(seconds),
            style: TextStyle(
              color: colors.primaryNeon,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final int hintsLeft;
  final AppColorsExtension colors;

  const _HintPill({required this.hintsLeft, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hasHints = hintsLeft > 0;
    final color = hasHints ? colors.accentPurple : colors.textDisabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: hasHints ? 0.75 : 0.3),
          width: 1.5,
        ),
        boxShadow: hasHints
            ? [
                BoxShadow(
                  color: colors.accentPurple.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 5),
          Text(
            '$hintsLeft',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
