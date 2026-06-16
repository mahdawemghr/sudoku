/// Pure-Dart hint explanations — no Flutter imports.
///
/// Given a target cell, determines which basic solving technique makes its
/// value forced (Naked Single, Hidden Single), or falls back to a neutral
/// message when the cell requires a longer chain of logic.
enum HintStrategy {
  nakedSingle,
  hiddenSingleBox,
  hiddenSingleRow,
  hiddenSingleColumn,
  logicalDeduction,
}

class HintExplanation {
  final HintStrategy strategy;
  final String title;
  final String reason;

  const HintExplanation({
    required this.strategy,
    required this.title,
    required this.reason,
  });
}

class HintExplainer {
  /// Explains why [solution]'s value at ([row], [col]) is correct, given the
  /// player's current progress in [currentGrid].
  static HintExplanation explain(
    List<List<int>> currentGrid,
    List<List<int>> solution,
    int row,
    int col,
  ) {
    final value = solution[row][col];

    // Any cell that doesn't match the solution is treated as empty, so a
    // wrong digit sitting in a peer cell can't corrupt candidate exclusion.
    final clean = _cleanGrid(currentGrid, solution);
    clean[row][col] = 0;

    if (_candidatesFor(clean, row, col).length == 1) {
      return HintExplanation(
        strategy: HintStrategy.nakedSingle,
        title: 'Last Number',
        reason: 'Every other number 1-9 is already used in this row, '
            'column, or box — $value is the only one left that fits here.',
      );
    }

    if (_isHiddenSingleInUnit(clean, _boxCells(row, col), row, col, value)) {
      return HintExplanation(
        strategy: HintStrategy.hiddenSingleBox,
        title: 'Only Spot Left in the Box',
        reason: 'Every other empty cell in this 3×3 box already has '
            '$value ruled out, so this is the only place left for it.',
      );
    }

    if (_isHiddenSingleInUnit(clean, _rowCells(row), row, col, value)) {
      return HintExplanation(
        strategy: HintStrategy.hiddenSingleRow,
        title: 'Only Spot Left in the Row',
        reason: 'Every other empty cell in this row already has $value '
            'ruled out, so this is the only place left for it.',
      );
    }

    if (_isHiddenSingleInUnit(clean, _colCells(col), row, col, value)) {
      return HintExplanation(
        strategy: HintStrategy.hiddenSingleColumn,
        title: 'Only Spot Left in the Column',
        reason: 'Every other empty cell in this column already has '
            '$value ruled out, so this is the only place left for it.',
      );
    }

    return HintExplanation(
      strategy: HintStrategy.logicalDeduction,
      title: 'No Easy Trick Here',
      reason: '$value is just the number that keeps the rest of the puzzle '
          "solvable — there's no quick one-step way to see it directly.",
    );
  }

  static List<List<int>> _cleanGrid(
    List<List<int>> currentGrid,
    List<List<int>> solution,
  ) {
    return List.generate(
      9,
      (r) => List.generate(9, (c) {
        final v = currentGrid[r][c];
        return v == solution[r][c] ? v : 0;
      }),
    );
  }

  static Set<int> _candidatesFor(List<List<int>> grid, int row, int col) {
    final used = <int>{};
    for (int i = 0; i < 9; i++) {
      used.add(grid[row][i]);
      used.add(grid[i][col]);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        used.add(grid[r][c]);
      }
    }
    used.remove(0);
    return {for (int n = 1; n <= 9; n++) n}..removeAll(used);
  }

  static bool _isHiddenSingleInUnit(
    List<List<int>> grid,
    List<(int, int)> unitCells,
    int row,
    int col,
    int value,
  ) {
    for (final (r, c) in unitCells) {
      if (r == row && c == col) continue;
      if (grid[r][c] != 0) continue;
      if (_candidatesFor(grid, r, c).contains(value)) return false;
    }
    return true;
  }

  static List<(int, int)> _rowCells(int row) =>
      [for (int c = 0; c < 9; c++) (row, c)];

  static List<(int, int)> _colCells(int col) =>
      [for (int r = 0; r < 9; r++) (r, col)];

  static List<(int, int)> _boxCells(int row, int col) {
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    return [
      for (int r = boxRow; r < boxRow + 3; r++)
        for (int c = boxCol; c < boxCol + 3; c++) (r, c),
    ];
  }
}
