import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/constants/app_constants.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/engine/sudoku_generator.dart';
import 'package:sudoku/features/game/state/game_state.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final gameDifficultyProvider =
    StateProvider<Difficulty>((ref) => Difficulty.easy);

final gameControllerProvider =
    StateNotifierProvider.autoDispose<GameController, GameState>((ref) {
  return GameController(
    gameRepository: GameRepository(),
    statsRepository: StatsRepository(),
  );
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class GameController extends StateNotifier<GameState> {
  final GameRepository _gameRepository;
  final StatsRepository _statsRepository;

  Timer? _timer;
  bool _timerRunning = false;

  /// Called when the game ends. Arguments: won, durationSeconds, isNewBest.
  void Function(bool won, int duration, bool isNewBest)? onGameOver;

  // Tracks mistakes count for saving to GameRecord.
  int _totalMistakes = 0;

  GameController({
    required GameRepository gameRepository,
    required StatsRepository statsRepository,
  })  : _gameRepository = gameRepository,
        _statsRepository = statsRepository,
        super(GameState.initial());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> startNewGame(Difficulty difficulty) async {
    _stopTimer();
    _totalMistakes = 0;

    state = GameState.initial().copyWith(
      difficulty: difficulty,
      phase: GamePhase.loading,
    );

    final result = await compute(
      SudokuGenerator.generatePuzzleIsolate,
      difficulty.toEngine().name,
    );

    final puzzle = result['puzzle']!;
    final solution = result['solution']!;

    // currentGrid starts as a copy of puzzle.
    final currentGrid =
        List.generate(9, (r) => List<int>.from(puzzle[r]));

    state = state.copyWith(
      currentGrid: currentGrid,
      puzzle: puzzle,
      solution: solution,
      difficulty: difficulty,
      phase: GamePhase.playing,
      selectedRow: -1,
      selectedCol: -1,
      livesLeft: AppConstants.maxLives,
      hintsLeft: AppConstants.maxHints,
      elapsedSeconds: 0,
      mistakeCells: {},
      undoStack: [],
    );

    _startTimer();
  }

  void selectCell(int row, int col) {
    if (state.phase != GamePhase.playing) return;
    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  void enterNumber(int number) {
    if (state.phase != GamePhase.playing) return;

    final r = state.selectedRow;
    final c = state.selectedCol;

    if (r == -1 || c == -1) return;
    if (state.isGiven(r, c)) return;
    if (state.currentGrid[r][c] == number) return;

    // Push current grid onto undo stack (deep copy).
    final gridSnapshot =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    final newUndoStack = [
      ...state.undoStack,
      gridSnapshot,
    ];

    // Apply the number.
    final newGrid =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    newGrid[r][c] = number;

    final flatIndex = r * 9 + c;
    final newMistakes = Set<int>.from(state.mistakeCells);

    if (number != state.solution[r][c]) {
      // Wrong answer.
      newMistakes.add(flatIndex);
      _totalMistakes++;
      final newLives = state.livesLeft - 1;

      if (newLives <= 0) {
        _stopTimer();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          livesLeft: 0,
          phase: GamePhase.lost,
        );
        _onGameOver(won: false);
      } else {
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          livesLeft: newLives,
        );
      }
    } else {
      // Correct answer.
      newMistakes.remove(flatIndex);

      state = state.copyWith(
        currentGrid: newGrid,
        undoStack: newUndoStack,
        mistakeCells: newMistakes,
      );

      if (_isGridComplete(newGrid)) {
        _stopTimer();
        state = state.copyWith(phase: GamePhase.won);
        _onGameOver(won: true);
      }
    }
  }

  void erase() {
    if (state.phase != GamePhase.playing) return;

    final r = state.selectedRow;
    final c = state.selectedCol;

    if (r == -1 || c == -1) return;
    if (state.isGiven(r, c)) return;
    if (state.currentGrid[r][c] == 0) return;

    final gridSnapshot =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    final newUndoStack = [...state.undoStack, gridSnapshot];

    final newGrid =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    newGrid[r][c] = 0;

    final newMistakes = Set<int>.from(state.mistakeCells)
      ..remove(r * 9 + c);

    state = state.copyWith(
      currentGrid: newGrid,
      undoStack: newUndoStack,
      mistakeCells: newMistakes,
    );
  }

  void undo() {
    if (state.phase != GamePhase.playing) return;
    if (state.undoStack.isEmpty) return;

    final newStack = List<List<List<int>>>.from(state.undoStack);
    final previousGrid = newStack.removeLast();

    // Recalculate mistake cells for the restored grid.
    final newMistakes = <int>{};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = previousGrid[r][c];
        if (val != 0 && val != state.solution[r][c]) {
          newMistakes.add(r * 9 + c);
        }
      }
    }

    state = state.copyWith(
      currentGrid: previousGrid,
      undoStack: newStack,
      mistakeCells: newMistakes,
    );
  }

  void pauseTimer() {
    if (_timerRunning) {
      _stopTimer();
    }
  }

  void resumeTimer() {
    if (!_timerRunning && state.phase == GamePhase.playing) {
      _startTimer();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void _stopTimer() {
    _timerRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  bool _isGridComplete(List<List<int>> grid) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != state.solution[r][c]) return false;
      }
    }
    return true;
  }

  Future<void> _onGameOver({required bool won}) async {
    final duration = state.elapsedSeconds;
    final difficulty = state.difficulty;

    final record = GameRecord(
      difficulty: difficulty,
      durationSeconds: duration,
      won: won,
      mistakes: _totalMistakes,
      completedAt: DateTime.now(),
    );

    await _gameRepository.saveRecord(record);

    bool isNewBest = false;
    if (won) {
      final prevBest = await _statsRepository.getBestTime(difficulty);
      if (prevBest == null || duration < prevBest) {
        isNewBest = true;
      }
    }

    onGameOver?.call(won, duration, isNewBest);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
