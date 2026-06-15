import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/engine/sudoku_validator.dart';

void main() {
  // A complete, valid Sudoku grid for use in tests.
  List<List<int>> _completedGrid() => [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];

  // The same grid with one cell cleared.
  List<List<int>> _partialGrid() {
    final g = _completedGrid();
    g[4][4] = 0;
    return g;
  }

  group('SudokuValidator.isValidMove()', () {
    test('returns true for a valid placement', () {
      final grid = _partialGrid(); // (4,4) is 0
      // The original value at (4,4) was 5 — placing 5 should be valid.
      expect(SudokuValidator.isValidMove(grid, 4, 4, 5), isTrue);
    });

    test('returns false for a row conflict', () {
      final grid = _partialGrid();
      // Row 4 contains: 4,2,6,8,_,3,7,9,1 — placing 4 conflicts
      expect(SudokuValidator.isValidMove(grid, 4, 4, 4), isFalse);
    });

    test('returns false for a column conflict', () {
      final grid = _partialGrid();
      // Column 4 contains: 7,9,4,6,_,2,3,1,8 — placing 7 conflicts
      expect(SudokuValidator.isValidMove(grid, 4, 4, 7), isFalse);
    });

    test('returns false for a box conflict', () {
      final grid = _partialGrid();
      // Center box (rows 3-5, cols 3-5) contains: 7,6,1,8,_,3,9,2,4
      // Placing 7 conflicts with the box value at (3,3)
      expect(SudokuValidator.isValidMove(grid, 4, 4, 7), isFalse);
    });
  });

  group('SudokuValidator.isComplete()', () {
    test('returns true for a fully valid grid', () {
      expect(SudokuValidator.isComplete(_completedGrid()), isTrue);
    });

    test('returns false for a grid with zeros', () {
      expect(SudokuValidator.isComplete(_partialGrid()), isFalse);
    });

    test('returns false for a grid with conflicts', () {
      final grid = _completedGrid();
      // Introduce a conflict: overwrite (0,1) from 3 to 5 (same as (0,0))
      grid[0][1] = 5;
      expect(SudokuValidator.isComplete(grid), isFalse);
    });
  });

  group('SudokuValidator.isCellCorrect()', () {
    test('returns true when cell value matches solution', () {
      final solution = _completedGrid();
      expect(SudokuValidator.isCellCorrect(solution, 0, 0, 5), isTrue);
    });

    test('returns false when cell value does not match solution', () {
      final solution = _completedGrid();
      expect(SudokuValidator.isCellCorrect(solution, 0, 0, 9), isFalse);
    });
  });
}
