import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/core/services/rewarded_ad_service.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/engine/hint_explainer.dart';
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

  /// Called after a hint reveals a cell (unless that hint also wins the game).
  void Function(HintExplanation explanation)? onHint;

  int _totalMistakes = 0;
  final GameSoundPlayer _sound;
  final RewardedAdProvider _ads;

  GameController({
    required GameRepository gameRepository,
    required StatsRepository statsRepository,
    GameSoundPlayer? soundService,
    RewardedAdProvider? adProvider,
  })  : _gameRepository = gameRepository,
        _statsRepository = statsRepository,
        _sound = soundService ?? SoundService(),
        _ads = adProvider ?? RewardedAdService(),
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
      hintsLeft: difficulty.maxHints,
      elapsedSeconds: 0,
      mistakeCells: {},
      undoStack: [],
      notesMode: false,
      notes: {},
    );

    _ads.preload();
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
      notes: saved.notes,
    );

    _ads.preload();
    _startTimer();
  }

  void selectCell(int row, int col) {
    if (state.phase != GamePhase.playing) return;
    _sound.playSelect();
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

    // Push a full snapshot (grid + notes + mistakes) onto the undo stack
    // before this move changes any of them, so undo can fully revert it.
    final newUndoStack = [...state.undoStack, _snapshot()];

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
        _sound.playWrong(); // not playLose() — the player may still revive
        _stopTimer();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          notes: newNotes,
          livesLeft: 0,
          phase: GamePhase.outOfLives,
        );
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

      // The number is confirmed correct, so it can no longer be a candidate
      // anywhere in the same row, column, or 3×3 box — clear it there too.
      for (int rr = 0; rr < 9; rr++) {
        for (int cc = 0; cc < 9; cc++) {
          final peerKey = rr * 9 + cc;
          if (peerKey == flatIndex) continue;
          final sameRow = rr == r;
          final sameCol = cc == c;
          final sameBox = (rr ~/ 3) == (r ~/ 3) && (cc ~/ 3) == (c ~/ 3);
          if (!sameRow && !sameCol && !sameBox) continue;

          final peerNotes = newNotes[peerKey];
          if (peerNotes == null || !peerNotes.contains(number)) continue;
          final updated = Set<int>.from(peerNotes)..remove(number);
          if (updated.isEmpty) {
            newNotes.remove(peerKey);
          } else {
            newNotes[peerKey] = updated;
          }
        }
      }

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

    final newUndoStack = [...state.undoStack, _snapshot()];

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

    final newStack = List<UndoSnapshot>.from(state.undoStack);
    final previous = newStack.removeLast();

    state = state.copyWith(
      currentGrid: previous.grid,
      undoStack: newStack,
      mistakeCells: previous.mistakeCells,
      notes: previous.notes,
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
    final explanation = HintExplainer.explain(state.currentGrid, state.solution, r, c);

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
      selectedRow: r,
      selectedCol: c,
    );

    if (_isGridComplete(newGrid)) {
      _stopTimer();
      state = state.copyWith(phase: GamePhase.won);
      _sound.playWin();
      _onGameOver(won: true);
    } else {
      _sound.playHint();
      _persistGame();
      onHint?.call(explanation);
    }
  }

  void toggleNotesMode() {
    if (state.phase != GamePhase.playing) return;
    _sound.playSelect();
    state = state.copyWith(notesMode: !state.notesMode);
  }

  void pauseTimer() {
    if (_timerRunning) _stopTimer();
  }

  void resumeTimer() {
    if (!_timerRunning && state.phase == GamePhase.playing) _startTimer();
  }

  /// Shows a rewarded ad and, if the player earns the reward, revives them
  /// with one life and resumes play. Otherwise finalizes the loss exactly
  /// like `declineRevive()`. No-op (returns false) outside `outOfLives`.
  Future<bool> requestRevive() async {
    if (state.phase != GamePhase.outOfLives) return false;
    final earned = await _ads.show();
    if (!mounted) return false;
    if (earned) {
      state = state.copyWith(livesLeft: 1, phase: GamePhase.playing);
      _startTimer();
      _persistGame();
      return true;
    }
    _finalizeLoss();
    return false;
  }

  /// Ends the game without showing an ad. No-op outside `outOfLives`.
  void declineRevive() {
    if (state.phase != GamePhase.outOfLives) return;
    _finalizeLoss();
  }

  void _finalizeLoss() {
    _sound.playLose();
    state = state.copyWith(phase: GamePhase.lost);
    _onGameOver(won: false);
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

  /// Captures the grid, notes, and mistake-tracking exactly as they are now,
  /// for pushing onto the undo stack before a move changes any of them.
  UndoSnapshot _snapshot() {
    return UndoSnapshot(
      grid: List.generate(9, (row) => List<int>.from(state.currentGrid[row])),
      notes: state.notes
          .map((key, value) => MapEntry(key, Set<int>.from(value))),
      mistakeCells: Set<int>.from(state.mistakeCells),
    );
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
      notes: state.notes,
    );
    _gameRepository.saveCurrentGame(saved).catchError((e) {
      debugPrint('[GameController] persistGame failed: $e');
    });
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
