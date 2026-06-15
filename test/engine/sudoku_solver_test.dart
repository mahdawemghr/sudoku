import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/engine/sudoku_solver.dart';

void main() {
  final solver = SudokuSolver();

  // A well-known easy puzzle (0 = empty)
  List<List<int>> easyPuzzle() => [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

  List<List<int>> easySolution() => [
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

  group('SudokuSolver.solve()', () {
    test('solves a known easy puzzle correctly', () {
      final grid = easyPuzzle();
      final solved = solver.solve(grid);
      expect(solved, isTrue);
      expect(grid, equals(easySolution()));
    });

    test('returns false for an unsolvable puzzle', () {
      // (0,0) is empty. Row 0 already has 1-8, so only 9 can go there.
      // But col 0 already has 9 at (1,0). Solver detects dead end immediately.
      final grid = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8],
        [9, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(solver.solve(grid), isFalse);
    });
  });

  group('SudokuSolver.isValidPlacement()', () {
    test('correctly rejects row conflicts', () {
      final grid = easyPuzzle();
      // Row 0 already has 5; placing 5 again should be invalid
      expect(solver.isValidPlacement(grid, 0, 2, 5), isFalse);
    });

    test('correctly rejects column conflicts', () {
      final grid = easyPuzzle();
      // Column 0 already has 5 (at row 0); placing 5 in col 0 elsewhere is invalid
      expect(solver.isValidPlacement(grid, 1, 0, 5), isFalse);
    });

    test('correctly rejects box conflicts', () {
      final grid = easyPuzzle();
      // Top-left box has 5 (0,0), 3 (0,1), 6 (1,0), 9 (2,1), 8 (2,2)
      // Placing 9 in (0,2) — same box as (2,1) — must be rejected
      expect(solver.isValidPlacement(grid, 0, 2, 9), isFalse);
    });

    test('returns true for a valid placement', () {
      final grid = easyPuzzle();
      // (0,2) is empty; 4 is not in row 0, col 2, or top-left box
      expect(solver.isValidPlacement(grid, 0, 2, 4), isTrue);
    });
  });

  group('SudokuSolver.countSolutions()', () {
    test('returns 1 for a valid unique-solution puzzle', () {
      final grid = easyPuzzle();
      expect(solver.countSolutions(grid, limit: 2), equals(1));
    });

    test('returns >= 2 (limit) for a puzzle with multiple solutions', () {
      // Almost-empty board — many solutions exist
      final grid = List.generate(9, (_) => List.filled(9, 0));
      // Place just one number to make it valid-but-ambiguous
      grid[0][0] = 1;
      expect(solver.countSolutions(grid, limit: 2), equals(2));
    });
  });
}
