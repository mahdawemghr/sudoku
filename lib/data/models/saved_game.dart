import 'dart:convert';

import 'difficulty.dart';

class SavedGame {
  final List<List<int>> currentGrid; // user's current grid state
  final List<List<int>> puzzle; // original puzzle (locked cells)
  final List<List<int>> solution; // full solution
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int livesLeft;
  final int hintsLeft;

  const SavedGame({
    required this.currentGrid,
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.livesLeft,
    required this.hintsLeft,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentGrid': currentGrid,
      'puzzle': puzzle,
      'solution': solution,
      'difficulty': difficulty.label,
      'elapsedSeconds': elapsedSeconds,
      'livesLeft': livesLeft,
      'hintsLeft': hintsLeft,
    };
  }

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    List<List<int>> parseGrid(dynamic raw) {
      return (raw as List)
          .map((row) => (row as List).map((v) => v as int).toList())
          .toList();
    }

    return SavedGame(
      currentGrid: parseGrid(json['currentGrid']),
      puzzle: parseGrid(json['puzzle']),
      solution: parseGrid(json['solution']),
      difficulty:
          DifficultyExtension.fromString(json['difficulty'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int,
      livesLeft: json['livesLeft'] as int,
      hintsLeft: json['hintsLeft'] as int,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SavedGame.fromJsonString(String s) =>
      SavedGame.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
