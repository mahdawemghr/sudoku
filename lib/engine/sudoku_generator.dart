import 'dart:math';

import 'sudoku_solver.dart';
import 'difficulty_rater.dart';

/// Pure-Dart Sudoku puzzle generator — no Flutter imports.
class SudokuGenerator {
  static final Random _rng = Random();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Generates a complete, valid, randomly shuffled 9×9 Sudoku solution.
  static List<List<int>> generateSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    _fillGrid(grid);
    return grid;
  }

  /// Generates a puzzle map with 'puzzle' and 'solution' keys.
  ///
  /// [difficulty] must be one of: 'easy', 'medium', 'hard', 'impossible'.
  static Map<String, List<List<int>>> generatePuzzle(
    EngineGivenDifficulty difficulty,
  ) {
    return _buildPuzzle(difficulty);
  }

  /// Isolate-compatible entry point for use with `compute()` in Flutter.
  ///
  /// [difficultyName] must be one of: 'easy', 'medium', 'hard', 'impossible'.
  static Map<String, List<List<int>>> generatePuzzleIsolate(
    String difficultyName,
  ) {
    final difficulty = _parseDifficulty(difficultyName);
    return _buildPuzzle(difficulty);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static Map<String, List<List<int>>> _buildPuzzle(
    EngineGivenDifficulty difficulty,
  ) {
    final solution = generateSolution();

    // Deep-copy solution into a mutable puzzle grid.
    final puzzle = List.generate(
      9,
      (r) => List<int>.from(solution[r]),
    );

    final targetRemovals = DifficultyRater.targetRemovalCount(difficulty);
    final solver = SudokuSolver();

    // Build a shuffled list of all 81 cell positions.
    final positions = [
      for (int r = 0; r < 9; r++)
        for (int c = 0; c < 9; c++) (r, c),
    ]..shuffle(_rng);

    int removed = 0;
    for (final (r, c) in positions) {
      if (removed >= targetRemovals) break;

      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      // Make a deep copy for the solution-count check (solver mutates in-place).
      final copy = List.generate(9, (row) => List<int>.from(puzzle[row]));
      if (solver.countSolutions(copy, limit: 2) == 1) {
        removed++;
      } else {
        // Restore — removal would create ambiguity.
        puzzle[r][c] = backup;
      }
    }

    return {'puzzle': puzzle, 'solution': solution};
  }

  /// Fills [grid] with a valid, random Sudoku solution using backtracking.
  /// Tries digits 1–9 in a shuffled order for randomness.
  static bool _fillGrid(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          final nums = _shuffled1to9();
          final solver = SudokuSolver();
          for (final n in nums) {
            if (solver.isValidPlacement(grid, r, c, n)) {
              grid[r][c] = n;
              if (_fillGrid(grid)) return true;
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static List<int> _shuffled1to9() {
    final list = List.generate(9, (i) => i + 1);
    list.shuffle(_rng);
    return list;
  }

  static EngineGivenDifficulty _parseDifficulty(String name) {
    switch (name.toLowerCase()) {
      case 'easy':
        return EngineGivenDifficulty.easy;
      case 'medium':
        return EngineGivenDifficulty.medium;
      case 'hard':
        return EngineGivenDifficulty.hard;
      case 'impossible':
        return EngineGivenDifficulty.impossible;
      default:
        throw ArgumentError('Unknown difficulty: $name');
    }
  }
}
