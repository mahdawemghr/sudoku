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
  // key: row*9+col, value: set of candidate numbers
  final Map<int, Set<int>> notes;

  const SavedGame({
    required this.currentGrid,
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.livesLeft,
    required this.hintsLeft,
    this.notes = const {},
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
      'notes': notes.map((k, v) => MapEntry(k.toString(), v.toList())),
    };
  }

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    List<List<int>> parseGrid(dynamic raw) {
      return (raw as List)
          .map((row) => (row as List).map((v) => v as int).toList())
          .toList();
    }

    final rawNotes = json['notes'] as Map<String, dynamic>?;

    return SavedGame(
      currentGrid: parseGrid(json['currentGrid']),
      puzzle: parseGrid(json['puzzle']),
      solution: parseGrid(json['solution']),
      difficulty:
          DifficultyExtension.fromString(json['difficulty'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int,
      livesLeft: json['livesLeft'] as int,
      hintsLeft: json['hintsLeft'] as int,
      notes: rawNotes == null
          ? const {}
          : rawNotes.map((k, v) =>
              MapEntry(int.parse(k), (v as List).map((e) => e as int).toSet())),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SavedGame.fromJsonString(String s) =>
      SavedGame.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
