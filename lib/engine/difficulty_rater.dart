// Pure-Dart difficulty rating for Sudoku puzzles — no Flutter imports.

enum EngineGivenDifficulty { easy, medium, hard, impossible }

class DifficultyRater {
  /// Returns the number of non-zero cells (clues) in [puzzle].
  static int countClues(List<List<int>> puzzle) {
    int count = 0;
    for (final row in puzzle) {
      for (final cell in row) {
        if (cell != 0) count++;
      }
    }
    return count;
  }

  /// Rates difficulty based solely on the number of given clues.
  ///
  /// Clue ranges (mirrored from generator targets):
  ///   Easy:       40–45 clues  (removed 36–41)
  ///   Medium:     32–39 clues  (removed 42–49)
  ///   Hard:       27–31 clues  (removed 50–54)
  ///   Impossible: 22–26 clues  (removed 55–59)
  static EngineGivenDifficulty rateByClues(List<List<int>> puzzle) {
    final clues = countClues(puzzle);
    if (clues >= 40) return EngineGivenDifficulty.easy;
    if (clues >= 32) return EngineGivenDifficulty.medium;
    if (clues >= 27) return EngineGivenDifficulty.hard;
    return EngineGivenDifficulty.impossible;
  }

  /// Returns how many cells to remove for [difficulty].
  /// The midpoint of each difficulty band is used as the target.
  static int targetRemovalCount(EngineGivenDifficulty difficulty) {
    switch (difficulty) {
      case EngineGivenDifficulty.easy:
        return 38; // removes 38 → leaves 43 clues
      case EngineGivenDifficulty.medium:
        return 45; // removes 45 → leaves 36 clues
      case EngineGivenDifficulty.hard:
        return 52; // removes 52 → leaves 29 clues
      case EngineGivenDifficulty.impossible:
        return 57; // removes 57 → leaves 24 clues
    }
  }
}
