import 'package:flutter/foundation.dart';
import 'package:sudoku/data/models/difficulty.dart';

enum GamePhase { loading, playing, won, lost }

@immutable
class GameState {
  final List<List<int>> currentGrid;
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final Difficulty difficulty;
  final GamePhase phase;
  final int selectedRow;
  final int selectedCol;
  final int livesLeft;
  final int hintsLeft;
  final int elapsedSeconds;
  final Set<int> mistakeCells;
  final List<List<List<int>>> undoStack;

  const GameState({
    required this.currentGrid,
    required this.puzzle,
    required this.solution,
    required this.difficulty,
    required this.phase,
    required this.selectedRow,
    required this.selectedCol,
    required this.livesLeft,
    required this.hintsLeft,
    required this.elapsedSeconds,
    required this.mistakeCells,
    required this.undoStack,
  });

  factory GameState.initial() {
    return GameState(
      currentGrid: List.generate(9, (_) => List.filled(9, 0)),
      puzzle: List.generate(9, (_) => List.filled(9, 0)),
      solution: List.generate(9, (_) => List.filled(9, 0)),
      difficulty: Difficulty.easy,
      phase: GamePhase.loading,
      selectedRow: -1,
      selectedCol: -1,
      livesLeft: 3,
      hintsLeft: 3,
      elapsedSeconds: 0,
      mistakeCells: const {},
      undoStack: const [],
    );
  }

  GameState copyWith({
    List<List<int>>? currentGrid,
    List<List<int>>? puzzle,
    List<List<int>>? solution,
    Difficulty? difficulty,
    GamePhase? phase,
    int? selectedRow,
    int? selectedCol,
    int? livesLeft,
    int? hintsLeft,
    int? elapsedSeconds,
    Set<int>? mistakeCells,
    List<List<List<int>>>? undoStack,
  }) {
    return GameState(
      currentGrid: currentGrid ?? this.currentGrid,
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      phase: phase ?? this.phase,
      selectedRow: selectedRow ?? this.selectedRow,
      selectedCol: selectedCol ?? this.selectedCol,
      livesLeft: livesLeft ?? this.livesLeft,
      hintsLeft: hintsLeft ?? this.hintsLeft,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakeCells: mistakeCells ?? this.mistakeCells,
      undoStack: undoStack ?? this.undoStack,
    );
  }

  bool get isLoading => phase == GamePhase.loading;

  bool isGiven(int row, int col) => puzzle[row][col] != 0;

  bool isSelected(int row, int col) => selectedRow == row && selectedCol == col;

  bool isMistake(int row, int col) => mistakeCells.contains(row * 9 + col);

  bool isCorrect(int row, int col) =>
      currentGrid[row][col] != 0 &&
      currentGrid[row][col] == solution[row][col];
}
