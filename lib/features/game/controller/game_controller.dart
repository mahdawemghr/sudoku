import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/constants/app_constants.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/core/services/sound_service.dart';
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

  int _totalMistakes = 0;
  final SoundService _sound = SoundService();

  GameController({
    required GameRepository gameRepository,
    required StatsRepository statsRepository,
  })  : _gameRepository = gameRepository,
        _statsRepository = statsRepository,
        super(GameState.initial()) {
    // Warm the database connection while the user is on the game loading screen
    // so the first game-over DB write is instant.
    _statsRepository.getBestTime(Difficulty.easy).ignore();
  }

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

    final currentGrid = List.generate(9, (r) => List<int>.from(puzzle[r]));

    state = state.copyWith(
      currentGrid: currentGrid,
      puzzle: puzzle,
      solution: solution,
      difficulty: difficulty,
      phase: GamePhase.playing,
      selectedRow: -1,
      selectedCol: -1,
      livesLeft: difficulty.maxLives,
      hintsLeft: AppConstants.maxHints,
      elapsedSeconds: 0,
      mistakeCells: {},
      undoStack: [],
      notesMode: false,
      notes: {},
    );

    _startTimer();
    _persistGame(); // Save immediately so resume works even before the first move.
  }

  Future<void> resumeGame(SavedGame saved) async {
    _stopTimer();
    _totalMistakes = 0;

    state = GameState.initial().copyWith(
      currentGrid: List.generate(9, (r) => List<int>.from(saved.currentGrid[r])),
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      phase: GamePhase.playing,
      selectedRow: -1,
      selectedCol: -1,
      livesLeft: saved.livesLeft,
      hintsLeft: saved.hintsLeft,
      elapsedSeconds: saved.elapsedSeconds,
      mistakeCells: {},
      undoStack: [],
      notesMode: false,
      notes: {},
    );

    _startTimer();
  }

  void selectCell(int row, int col) {
    if (state.phase != GamePhase.playing) return;
    if (state.selectedRow == row && state.selectedCol == col) {
      state = state.copyWith(selectedRow: -1, selectedCol: -1);
    } else {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }

  void enterNumber(int number) {
    if (state.phase != GamePhase.playing) return;

    final r = state.selectedRow;
    final c = state.selectedCol;

    if (r == -1 || c == -1) return;
    if (state.isGiven(r, c)) return;

    // Notes mode: toggle candidate instead of placing a number.
    if (state.notesMode) {
      if (state.currentGrid[r][c] != 0) return; // cell already filled
      final key = r * 9 + c;
      final newNotes = Map<int, Set<int>>.from(state.notes);
      final cellNotes = Set<int>.from(newNotes[key] ?? {});
      if (cellNotes.contains(number)) {
        cellNotes.remove(number);
      } else {
        cellNotes.add(number);
      }
      newNotes[key] = cellNotes;
      state = state.copyWith(notes: newNotes);
      _persistGame();
      return;
    }

    if (state.currentGrid[r][c] == number) return;

    // Push current grid onto undo stack (deep copy).
    final gridSnapshot =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    final newUndoStack = [...state.undoStack, gridSnapshot];

    final newGrid =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    newGrid[r][c] = number;

    final flatIndex = r * 9 + c;
    final newMistakes = Set<int>.from(state.mistakeCells);

    // Clear notes for this cell when a number is placed.
    final newNotes = Map<int, Set<int>>.from(state.notes)..remove(flatIndex);

    if (number != state.solution[r][c]) {
      newMistakes.add(flatIndex);
      _totalMistakes++;

      final newLives = state.livesLeft - 1;
      if (newLives <= 0) {
        _sound.playLose();
        _stopTimer();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          notes: newNotes,
          livesLeft: 0,
          phase: GamePhase.lost,
        );
        _onGameOver(won: false);
      } else {
        _sound.playWrong();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          notes: newNotes,
          livesLeft: newLives,
        );
        _persistGame();
      }
    } else {
      newMistakes.remove(flatIndex);

      state = state.copyWith(
        currentGrid: newGrid,
        undoStack: newUndoStack,
        mistakeCells: newMistakes,
        notes: newNotes,
      );

      if (_isGridComplete(newGrid)) {
        _stopTimer();
        state = state.copyWith(phase: GamePhase.won);
        _sound.playWin();
        _onGameOver(won: true);
      } else {
        _sound.playCorrect();
        _persistGame();
      }
    }
  }

  void erase() {
    if (state.phase != GamePhase.playing) return;

    final r = state.selectedRow;
    final c = state.selectedCol;

    if (r == -1 || c == -1) return;
    if (state.isGiven(r, c)) return;

    final key = r * 9 + c;

    // If notes exist, clear them first.
    if (state.notes.containsKey(key)) {
      final newNotes = Map<int, Set<int>>.from(state.notes)..remove(key);
      state = state.copyWith(notes: newNotes);
      _sound.playErase();
      _persistGame();
      return;
    }

    if (state.currentGrid[r][c] == 0) return;

    final gridSnapshot =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    final newUndoStack = [...state.undoStack, gridSnapshot];

    final newGrid =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    newGrid[r][c] = 0;

    final newMistakes = Set<int>.from(state.mistakeCells)..remove(key);

    state = state.copyWith(
      currentGrid: newGrid,
      undoStack: newUndoStack,
      mistakeCells: newMistakes,
    );
    _sound.playErase();
    _persistGame();
  }

  void undo() {
    if (state.phase != GamePhase.playing) return;
    if (state.undoStack.isEmpty) return;

    final newStack = List<List<List<int>>>.from(state.undoStack);
    final previousGrid = newStack.removeLast();

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
    _sound.playUndo();
    _persistGame();
  }

  void hint() {
    if (state.phase != GamePhase.playing) return;
    if (state.hintsLeft <= 0) return;

    // Collect all empty or wrong cells.
    final candidates = <(int, int)>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!state.isGiven(r, c) &&
            state.currentGrid[r][c] != state.solution[r][c]) {
          candidates.add((r, c));
        }
      }
    }
    if (candidates.isEmpty) return;

    // Pick the selected cell if it's a candidate, otherwise pick first.
    (int, int) target;
    if (state.selectedRow != -1 &&
        state.selectedCol != -1 &&
        candidates.contains((state.selectedRow, state.selectedCol))) {
      target = (state.selectedRow, state.selectedCol);
    } else {
      target = candidates.first;
    }

    final (r, c) = target;
    final newGrid =
        List.generate(9, (row) => List<int>.from(state.currentGrid[row]));
    newGrid[r][c] = state.solution[r][c];

    final flatIndex = r * 9 + c;
    final newMistakes = Set<int>.from(state.mistakeCells)..remove(flatIndex);
    final newNotes = Map<int, Set<int>>.from(state.notes)..remove(flatIndex);

    state = state.copyWith(
      currentGrid: newGrid,
      mistakeCells: newMistakes,
      notes: newNotes,
      hintsLeft: state.hintsLeft - 1,
    );

    if (_isGridComplete(newGrid)) {
      _stopTimer();
      state = state.copyWith(phase: GamePhase.won);
      _sound.playWin();
      _onGameOver(won: true);
    } else {
      _sound.playHint();
      _persistGame();
    }
  }

  void toggleNotesMode() {
    if (state.phase != GamePhase.playing) return;
    state = state.copyWith(notesMode: !state.notesMode);
  }

  void pauseTimer() {
    if (_timerRunning) _stopTimer();
  }

  void resumeTimer() {
    if (!_timerRunning && state.phase == GamePhase.playing) _startTimer();
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

  void _persistGame() {
    final saved = SavedGame(
      currentGrid: List.generate(9, (r) => List<int>.from(state.currentGrid[r])),
      puzzle: state.puzzle,
      solution: state.solution,
      difficulty: state.difficulty,
      elapsedSeconds: state.elapsedSeconds,
      livesLeft: state.livesLeft,
      hintsLeft: state.hintsLeft,
    );
    _gameRepository.saveCurrentGame(saved);
  }

  Future<void> _onGameOver({required bool won}) async {
    // Snapshot mutable values before any async gap.
    final difficulty = state.difficulty;
    final duration = state.elapsedSeconds;
    final totalMistakes = _totalMistakes;

    bool isNewBest = false;
    try {
      if (won) {
        final prevBest = await _statsRepository.getBestTime(difficulty);
        if (prevBest == null || duration < prevBest) isNewBest = true;
      }
    } catch (e) {
      debugPrint('[GameController] getBestTime failed: $e');
    }

    // Save BEFORE navigating so the record persists before autoDispose fires.
    try {
      final record = GameRecord(
        difficulty: difficulty,
        durationSeconds: duration,
        won: won,
        mistakes: totalMistakes,
        completedAt: DateTime.now(),
      );
      await _gameRepository.clearCurrentGame();
      await _gameRepository.saveRecord(record);
      debugPrint('[GameController] game saved — difficulty:${difficulty.label} won:$won duration:${duration}s');
    } catch (e) {
      debugPrint('[GameController] saveRecord failed: $e');
    }

    onGameOver?.call(won, duration, isNewBest);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
