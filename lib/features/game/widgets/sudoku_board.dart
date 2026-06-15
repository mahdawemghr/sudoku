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
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cellSize = size / 9;

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _BoardGridPainter(
              borderColor: colors.border,
              primaryNeon: colors.primaryNeon,
            ),
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
                          isHighlighted: gameState.isHighlighted(row, col),
                          isSameNumber: gameState.isSameNumber(row, col),
                          notes: gameState.notesFor(row, col),
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
  final Color borderColor;
  final Color primaryNeon;

  const _BoardGridPainter({
    required this.borderColor,
    required this.primaryNeon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;

    final thinPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final thickPaint = Paint()
      ..color = primaryNeon.withValues(alpha: 0.4)
      ..strokeWidth = 2.0;

    final outerPaint = Paint()
      ..color = primaryNeon.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) continue;
      final x = i * cellSize;
      final y = i * cellSize;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thinPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thinPaint);
    }

    for (int i = 3; i < 9; i += 3) {
      final x = i * cellSize;
      final y = i * cellSize;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thickPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thickPaint);
    }

    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      outerPaint,
    );
  }

  @override
  bool shouldRepaint(_BoardGridPainter old) =>
      old.borderColor != borderColor || old.primaryNeon != primaryNeon;
}
