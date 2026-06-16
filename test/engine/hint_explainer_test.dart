import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/engine/hint_explainer.dart';

List<List<int>> _emptyGrid() => List.generate(9, (_) => List.filled(9, 0));

void main() {
  group('HintExplainer', () {
    test('naked single — only one digit fits once everything else is filled', () {
      // A real solved Sudoku grid; clearing a single cell pins it via row
      // alone, since every other digit in that row is already placed.
      final solution = [
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
      final current = List.generate(9, (r) => List<int>.from(solution[r]));
      current[0][0] = 0;

      final result = HintExplainer.explain(current, solution, 0, 0);

      expect(result.strategy, HintStrategy.nakedSingle);
      expect(result.reason, contains('5'));
    });

    test('hidden single in box — value is blocked everywhere else in the box', () {
      final solution = _emptyGrid();
      final current = _emptyGrid();
      // Fill 7 of the 9 cells in box(0,0), leaving only (0,0) and (0,1)
      // empty. The box alone leaves {5, 9} as candidates for (0,0).
      const filled = {
        (0, 2): 1,
        (1, 0): 2,
        (1, 1): 3,
        (1, 2): 4,
        (2, 0): 6,
        (2, 1): 7,
        (2, 2): 8,
      };
      for (final entry in filled.entries) {
        final (r, c) = entry.key;
        solution[r][c] = entry.value;
        current[r][c] = entry.value;
      }
      // Blocks (0,1) from ever holding 5, via its column — outside the box.
      solution[5][1] = 5;
      current[5][1] = 5;
      solution[0][0] = 5;
      solution[0][1] = 9;
      // (0,0) and (0,1) stay 0 in `current` (unsolved).

      final result = HintExplainer.explain(current, solution, 0, 0);

      expect(result.strategy, HintStrategy.hiddenSingleBox);
      expect(result.reason, contains('5'));
    });

    test('hidden single in row — value is blocked everywhere else in the row', () {
      final solution = _emptyGrid();
      final current = _emptyGrid();
      // Row 4 is filled except (4,4) [target] and (4,5); box(1,1) and
      // column 4 are otherwise empty so they don't add extra exclusions.
      const row4 = {0: 1, 1: 2, 2: 3, 3: 4, 6: 5, 7: 6, 8: 8};
      for (final entry in row4.entries) {
        solution[4][entry.key] = entry.value;
        current[4][entry.key] = entry.value;
      }
      solution[4][4] = 7;
      solution[4][5] = 9;
      // Blocks (4,5) from holding 7 via its column, outside box(1,1).
      solution[7][5] = 7;
      current[7][5] = 7;

      final result = HintExplainer.explain(current, solution, 4, 4);

      expect(result.strategy, HintStrategy.hiddenSingleRow);
      expect(result.reason, contains('7'));
    });

    test('hidden single in column — value is blocked everywhere else in the column', () {
      final solution = _emptyGrid();
      final current = _emptyGrid();
      // Column 4 is filled except (4,4) [target] and (5,4); box(1,1) and
      // row 4 are otherwise empty so they don't add extra exclusions.
      const col4 = {0: 1, 1: 2, 2: 3, 3: 4, 6: 5, 7: 6, 8: 8};
      for (final entry in col4.entries) {
        solution[entry.key][4] = entry.value;
        current[entry.key][4] = entry.value;
      }
      solution[4][4] = 7;
      solution[5][4] = 9;
      // Blocks (5,4) from holding 7 via its row, outside box(1,1).
      solution[5][7] = 7;
      current[5][7] = 7;

      final result = HintExplainer.explain(current, solution, 4, 4);

      expect(result.strategy, HintStrategy.hiddenSingleColumn);
      expect(result.reason, contains('7'));
    });

    test('falls back to logical deduction when no simple strategy applies', () {
      final solution = _emptyGrid();
      final current = _emptyGrid();
      // An otherwise-empty board: every unit has many open cells able to
      // take the value, so neither naked nor hidden single applies.
      solution[2][2] = 5;

      final result = HintExplainer.explain(current, solution, 2, 2);

      expect(result.strategy, HintStrategy.logicalDeduction);
      expect(result.reason, contains('5'));
    });
  });
}
