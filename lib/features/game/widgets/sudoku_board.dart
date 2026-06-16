import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/sudoku_cell.dart';

class SudokuBoard extends ConsumerStatefulWidget {
  const SudokuBoard({super.key});

  @override
  ConsumerState<SudokuBoard> createState() => _SudokuBoardState();
}

class _SudokuBoardState extends ConsumerState<SudokuBoard> {
  // cellIndex (row*9+col) → stagger step for the celebration animation
  final Map<int, int> _celebratingCells = {};
  Timer? _clearTimer;

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  void _onStateChange(GameState? prev, GameState next) {
    if (prev == null || next.isLoading || prev.isLoading) return;

    final Map<int, int> newCelebrating = {};

    // Rows — stagger left→right
    for (int r = 0; r < 9; r++) {
      if (!prev.isRowComplete(r) && next.isRowComplete(r)) {
        for (int c = 0; c < 9; c++) {
          newCelebrating[r * 9 + c] = c;
        }
      }
    }

    // Cols — stagger top→bottom
    for (int c = 0; c < 9; c++) {
      if (!prev.isColComplete(c) && next.isColComplete(c)) {
        for (int r = 0; r < 9; r++) {
          newCelebrating[r * 9 + c] = r;
        }
      }
    }

    // 3×3 boxes — stagger in reading order
    for (int b = 0; b < 9; b++) {
      if (!prev.isBoxComplete(b) && next.isBoxComplete(b)) {
        final br = (b ~/ 3) * 3;
        final bc = (b % 3) * 3;
        int step = 0;
        for (int r = br; r < br + 3; r++) {
          for (int c = bc; c < bc + 3; c++) {
            newCelebrating[r * 9 + c] = step++;
          }
        }
      }
    }

    if (newCelebrating.isEmpty) return;

    setState(() {
      _celebratingCells.addAll(newCelebrating);
    });

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _celebratingCells.clear());
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final colors = context.appColors;

    ref.listen<GameState>(gameControllerProvider, _onStateChange);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cellSize = size / 9;

        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            // Drawn as a foreground painter so the grid lines sit on top of
            // each cell's (often fully opaque) background instead of being
            // covered by it.
            foregroundPainter: _BoardGridPainter(
              borderColor: colors.border,
              primaryNeon: colors.primaryNeon,
            ),
            child: Column(
              children: List.generate(9, (row) {
                return SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(9, (col) {
                      final cellIdx = row * 9 + col;
                      return SizedBox(
                        width: cellSize,
                        height: cellSize,
                        child: SudokuCell(
                          key: ValueKey(cellIdx),
                          value: gameState.currentGrid[row][col],
                          isGiven: gameState.isGiven(row, col),
                          isSelected: gameState.isSelected(row, col),
                          isMistake: gameState.isMistake(row, col),
                          isCorrect: gameState.isCorrect(row, col),
                          isHighlighted: gameState.isHighlighted(row, col),
                          isSameNumber: gameState.isSameNumber(row, col),
                          notes: gameState.notesFor(row, col),
                          highlightedNote: gameState.selectedValue,
                          celebrationStep: _celebratingCells[cellIdx],
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
      ..color = borderColor.withValues(alpha: 0.55)
      ..strokeWidth = 0.6;

    final thickPaint = Paint()
      ..color = primaryNeon.withValues(alpha: 0.9)
      ..strokeWidth = 2.5;

    final outerPaint = Paint()
      ..color = primaryNeon.withValues(alpha: 0.95)
      ..strokeWidth = 3.0
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
