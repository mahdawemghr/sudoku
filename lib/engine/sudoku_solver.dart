/// Pure-Dart Sudoku solver — no Flutter imports.
class SudokuSolver {
  /// Solves [grid] in-place using backtracking.
  /// Returns `true` if a solution was found, `false` if unsolvable.
  bool solve(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          for (int n = 1; n <= 9; n++) {
            if (isValidPlacement(grid, r, c, n)) {
              grid[r][c] = n;
              if (solve(grid)) return true;
              grid[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Returns `true` if placing [num] at ([row], [col]) violates no constraints.
  bool isValidPlacement(List<List<int>> grid, int row, int col, int num) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (grid[row][c] == num) return false;
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      if (grid[r][col] == num) return false;
    }
    // Check 3×3 box
    final int boxRow = (row ~/ 3) * 3;
    final int boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }

  /// Counts solutions up to [limit].
  /// Call with `limit: 2` to distinguish unique (1) from ambiguous (>1).
  int countSolutions(List<List<int>> grid, {int limit = 2}) {
    return _count(grid, limit);
  }

  int _count(List<List<int>> grid, int limit) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] == 0) {
          int count = 0;
          for (int n = 1; n <= 9; n++) {
            if (isValidPlacement(grid, r, c, n)) {
              grid[r][c] = n;
              count += _count(grid, limit - count);
              grid[r][c] = 0;
              if (count >= limit) return count;
            }
          }
          return count;
        }
      }
    }
    return 1; // All cells filled — one valid solution.
  }
}
