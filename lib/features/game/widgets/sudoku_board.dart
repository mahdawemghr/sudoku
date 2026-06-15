import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/widgets/sudoku_cell.dart';

class SudokuBoard extends ConsumerWidget {
  const SudokuBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cellSize = size / 9;

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BoardGridPainter(),
            child: Column(
              children: List.generate(9, (row) {
                return SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(9, (col) {
                      return SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: SudokuCell(
                          value: gameState.currentGrid[row][col],
                          isGiven: gameState.isGiven(row, col),
                          isSelected: gameState.isSelected(row, col),
                          isMistake: gameState.isMistake(row, col),
                          isCorrect: gameState.isCorrect(row, col),
                          onTap: () => controller.selectCell(row, col),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;

    final thinPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final thickPaint = Paint()
      ..color = AppColors.primaryNeon.withValues(alpha: 0.4)
      ..strokeWidth = 2.0;

    final outerPaint = Paint()
      ..color = AppColors.primaryNeon.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw thin lines between individual cells.
    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) continue; // box borders drawn separately
      final x = i * cellSize;
      final y = i * cellSize;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thinPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thinPaint);
    }

    // Draw thick lines between 3x3 boxes.
    for (int i = 3; i < 9; i += 3) {
      final x = i * cellSize;
      final y = i * cellSize;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thickPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thickPaint);
    }

    // Draw outer border.
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      outerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
