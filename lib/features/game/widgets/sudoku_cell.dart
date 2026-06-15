import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sudoku/core/theme/app_colors.dart';

class SudokuCell extends StatelessWidget {
  final int value;
  final bool isGiven;
  final bool isSelected;
  final bool isMistake;
  final bool isCorrect;
  final bool isHighlighted;
  final bool isSameNumber;
  final Set<int> notes;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.value,
    required this.isGiven,
    required this.isSelected,
    required this.isMistake,
    required this.isCorrect,
    required this.isHighlighted,
    required this.isSameNumber,
    required this.notes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Color backgroundColor;
    if (isMistake) {
      backgroundColor = colors.errorRed.withValues(alpha: 0.22);
    } else if (isSelected) {
      backgroundColor = colors.primaryNeon.withValues(alpha: 0.18);
    } else if (isSameNumber) {
      backgroundColor = colors.primaryNeon.withValues(alpha: 0.10);
    } else if (isHighlighted) {
      backgroundColor = colors.surfaceVariant;
    } else if (isGiven) {
      backgroundColor = colors.surface.withValues(alpha: 0.7);
    } else {
      backgroundColor = colors.surface;
    }

    final Color textColor;
    if (isMistake) {
      textColor = colors.errorRed;
    } else if (isCorrect) {
      textColor = colors.secondaryNeon;
    } else if (isGiven) {
      textColor = colors.textPrimary;
    } else {
      textColor = colors.primaryNeon;
    }

    final borderColor =
        isSelected ? colors.primaryNeon : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 0.0,
          ),
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  key: ValueKey(value),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight:
                        isGiven ? FontWeight.bold : FontWeight.w500,
                  ),
                )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 120.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 80.ms)
              : notes.isNotEmpty
                  ? _NotesGrid(notes: notes)
                  : null,
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  final Set<int> notes;

  const _NotesGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    final accentPurple = context.appColors.accentPurple;
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final n = i + 1;
          return Center(
            child: notes.contains(n)
                ? Text(
                    '$n',
                    style: TextStyle(
                      color: accentPurple,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ),
    );
  }
}
