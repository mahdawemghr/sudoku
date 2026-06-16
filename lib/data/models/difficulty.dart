import 'package:sudoku/engine/difficulty_rater.dart';

enum Difficulty { easy, medium, hard, impossible }

extension DifficultyExtension on Difficulty {
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.impossible:
        return 'Impossible';
    }
  }

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
      case Difficulty.impossible:
        return 'impossible';
    }
  }

  EngineGivenDifficulty toEngine() {
    switch (this) {
      case Difficulty.easy:
        return EngineGivenDifficulty.easy;
      case Difficulty.medium:
        return EngineGivenDifficulty.medium;
      case Difficulty.hard:
        return EngineGivenDifficulty.hard;
      case Difficulty.impossible:
        return EngineGivenDifficulty.impossible;
    }
  }

  int get maxLives {
    switch (this) {
      case Difficulty.easy:
        return 5;
      case Difficulty.medium:
        return 4;
      case Difficulty.hard:
        return 3;
      case Difficulty.impossible:
        return 1;
    }
  }

  int get maxHints {
    switch (this) {
      case Difficulty.easy:
        return 5;
      case Difficulty.medium:
        return 3;
      case Difficulty.hard:
        return 2;
      case Difficulty.impossible:
        return 1;
    }
  }

  static Difficulty fromString(String s) {
    switch (s.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'impossible':
        return Difficulty.impossible;
      default:
        throw ArgumentError('Unknown difficulty: $s');
    }
  }
}
