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
  final bool notesMode;
  // key: row*9+col, value: set of candidate numbers
  final Map<int, Set<int>> notes;

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
    required this.notesMode,
    required this.notes,
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
      notesMode: false,
      notes: const {},
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
    bool? notesMode,
    Map<int, Set<int>>? notes,
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
      notesMode: notesMode ?? this.notesMode,
      notes: notes ?? this.notes,
    );
  }

  bool get isLoading => phase == GamePhase.loading;

  bool isGiven(int row, int col) => puzzle[row][col] != 0;

  bool isSelected(int row, int col) => selectedRow == row && selectedCol == col;

  bool isMistake(int row, int col) => mistakeCells.contains(row * 9 + col);

  bool isCorrect(int row, int col) =>
      currentGrid[row][col] != 0 &&
      currentGrid[row][col] == solution[row][col];

  bool isHighlighted(int row, int col) {
    if (selectedRow == -1 || selectedCol == -1) return false;
    if (isSelected(row, col)) return false;
    // Same row, column, or 3×3 box
    final sameRow = row == selectedRow;
    final sameCol = col == selectedCol;
    final sameBox = (row ~/ 3) == (selectedRow ~/ 3) &&
        (col ~/ 3) == (selectedCol ~/ 3);
    return sameRow || sameCol || sameBox;
  }

  bool isSameNumber(int row, int col) {
    if (selectedRow == -1 || selectedCol == -1) return false;
    if (isSelected(row, col)) return false;
    final selectedValue = currentGrid[selectedRow][selectedCol];
    if (selectedValue == 0) return false;
    return currentGrid[row][col] == selectedValue;
  }

  Set<int> notesFor(int row, int col) {
    return notes[row * 9 + col] ?? const {};
  }

  bool isRowComplete(int row) {
    for (int c = 0; c < 9; c++) {
      if (currentGrid[row][c] == 0 || currentGrid[row][c] != solution[row][c]) return false;
    }
    return true;
  }

  bool isColComplete(int col) {
    for (int r = 0; r < 9; r++) {
      if (currentGrid[r][col] == 0 || currentGrid[r][col] != solution[r][col]) return false;
    }
    return true;
  }

  bool isBoxComplete(int box) {
    final br = (box ~/ 3) * 3;
    final bc = (box % 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (currentGrid[r][c] == 0 || currentGrid[r][c] != solution[r][c]) return false;
      }
    }
    return true;
  }
}
