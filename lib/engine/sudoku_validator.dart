/// Pure-Dart Sudoku validator — no Flutter imports.
class SudokuValidator {
  /// Returns `true` if placing [num] at ([row], [col]) is valid
  /// given the current state of [grid].
  ///
  /// Does NOT check whether the cell is already occupied — the caller
  /// is responsible for that if needed.
  static bool isValidMove(
    List<List<int>> grid,
    int row,
    int col,
    int num,
  ) {
    // Row check
    for (int c = 0; c < 9; c++) {
      if (c != col && grid[row][c] == num) return false;
    }
    // Column check
    for (int r = 0; r < 9; r++) {
      if (r != row && grid[r][col] == num) return false;
    }
    // 3×3 box check
    final int boxRow = (row ~/ 3) * 3;
    final int boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if ((r != row || c != col) && grid[r][c] == num) return false;
      }
    }
    return true;
  }

  /// Returns `true` if [grid] is fully filled (no zeros) and has no conflicts.
  static bool isComplete(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = grid[r][c];
        if (val == 0) return false;
        if (!isValidMove(grid, r, c, val)) return false;
      }
    }
    return true;
  }

  /// Returns `true` if the cell at ([row], [col]) in [solution] equals [value].
  static bool isCellCorrect(
    List<List<int>> solution,
    int row,
    int col,
    int value,
  ) {
    return solution[row][col] == value;
  }
}
