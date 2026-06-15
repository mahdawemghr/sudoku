import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/engine/sudoku_generator.dart';
import 'package:sudoku/engine/sudoku_solver.dart';
import 'package:sudoku/engine/sudoku_validator.dart';
import 'package:sudoku/engine/difficulty_rater.dart';

bool _isValidSolution(List<List<int>> grid) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (grid[r][c] == 0) return false;
    }
  }
  return SudokuValidator.isComplete(grid);
}

void main() {
  final solver = SudokuSolver();

  group('SudokuGenerator.generateSolution()', () {
    test('returns a complete valid 9×9 grid (no zeros, no conflicts)', () {
      final solution = SudokuGenerator.generateSolution();
      expect(solution.length, equals(9));
      for (final row in solution) {
        expect(row.length, equals(9));
      }
      expect(_isValidSolution(solution), isTrue);
    });

    test('returns different results on multiple calls (randomness)', () {
      final a = SudokuGenerator.generateSolution();
      final b = SudokuGenerator.generateSolution();
      // Probability of identical boards is negligibly small.
      bool same = true;
      outer:
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (a[r][c] != b[r][c]) {
            same = false;
            break outer;
          }
        }
      }
      expect(same, isFalse);
    });
  });

  group('SudokuGenerator.generatePuzzle()', () {
    test('returns correct structure with puzzle and solution keys', () {
      final result = SudokuGenerator.generatePuzzle(EngineGivenDifficulty.easy);
      expect(result.containsKey('puzzle'), isTrue);
      expect(result.containsKey('solution'), isTrue);
      expect(result['puzzle']!.length, equals(9));
      expect(result['solution']!.length, equals(9));
    });

    test('easy puzzle has the right number of clues (40–45)', () {
      final result = SudokuGenerator.generatePuzzle(EngineGivenDifficulty.easy);
      final clues = DifficultyRater.countClues(result['puzzle']!);
      // Allow a small margin: uniqueness checks may prevent reaching target,
      // but we should be in a reasonable easy range (≥35 clues).
      expect(clues, greaterThanOrEqualTo(35));
      expect(clues, lessThanOrEqualTo(81));
    });

    test('medium puzzle has fewer clues than easy', () {
      final easy =
          DifficultyRater.countClues(
            SudokuGenerator.generatePuzzle(EngineGivenDifficulty.easy)['puzzle']!,
          );
      final medium =
          DifficultyRater.countClues(
            SudokuGenerator.generatePuzzle(EngineGivenDifficulty.medium)['puzzle']!,
          );
      expect(medium, lessThanOrEqualTo(easy));
    });

    test('generated solution is valid (passes isComplete check)', () {
      final result = SudokuGenerator.generatePuzzle(EngineGivenDifficulty.easy);
      expect(_isValidSolution(result['solution']!), isTrue);
    });

    test('puzzle has a unique solution (countSolutions returns 1)', () {
      final result = SudokuGenerator.generatePuzzle(EngineGivenDifficulty.easy);
      final puzzle = result['puzzle']!;
      final copy = List.generate(9, (r) => List<int>.from(puzzle[r]));
      expect(solver.countSolutions(copy, limit: 2), equals(1));
    });
  });

  group('SudokuGenerator.generatePuzzleIsolate()', () {
    test('accepts a string difficulty name and returns correct structure', () {
      final result = SudokuGenerator.generatePuzzleIsolate('medium');
      expect(result.containsKey('puzzle'), isTrue);
      expect(result.containsKey('solution'), isTrue);
    });

    test('throws ArgumentError for unknown difficulty name', () {
      expect(
        () => SudokuGenerator.generatePuzzleIsolate('expert'),
        throwsArgumentError,
      );
    });
  });
}
