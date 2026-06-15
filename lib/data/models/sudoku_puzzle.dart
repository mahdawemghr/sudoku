import 'difficulty.dart';

class SudokuPuzzle {
  final List<List<int>> puzzle; // 0 = empty
  final List<List<int>> solution;
  final Difficulty difficulty;

  const SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.difficulty,
  });
}
