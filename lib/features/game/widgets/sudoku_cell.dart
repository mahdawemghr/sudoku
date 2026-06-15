import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';

class SudokuCell extends StatelessWidget {
  final int value;
  final bool isGiven;
  final bool isSelected;
  final bool isMistake;
  final bool isCorrect;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.value,
    required this.isGiven,
    required this.isSelected,
    required this.isMistake,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor();
    final textColor = _textColor();
    final borderColor = isSelected ? AppColors.primaryNeon : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
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
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight:
                        isGiven ? FontWeight.bold : FontWeight.w500,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Color _backgroundColor() {
    if (isMistake) {
      return AppColors.errorRed.withValues(alpha: 0.25);
    }
    if (isSelected) {
      return AppColors.primaryNeon.withValues(alpha: 0.12);
    }
    if (isGiven) {
      return AppColors.surfaceVariant;
    }
    return AppColors.surface;
  }

  Color _textColor() {
    if (isMistake) {
      return AppColors.errorRed;
    }
    if (isCorrect) {
      return AppColors.secondaryNeon;
    }
    if (isGiven) {
      return AppColors.textPrimary;
    }
    return AppColors.primaryNeon;
  }
}
