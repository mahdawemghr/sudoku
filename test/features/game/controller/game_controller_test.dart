import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/services/rewarded_ad_service.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/data/datasources/game_history_dao.dart';
import 'package:sudoku/data/datasources/settings_store.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/game_record.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';

/// No-op sound player — avoids constructing a real SoundService, which
/// eagerly creates a platform AudioPlayer outside of a running app.
class _FakeSoundPlayer implements GameSoundPlayer {
  @override
  void setSoundEnabled(bool enabled) {}
  @override
  Future<void> playCorrect() async {}
  @override
  Future<void> playWrong() async {}
  @override
  Future<void> playWin() async {}
  @override
  Future<void> playLose() async {}
  @override
  Future<void> playHint() async {}
  @override
  Future<void> playUndo() async {}
  @override
  Future<void> playErase() async {}
  @override
  Future<void> playTap() async {}
  @override
  Future<void> playSelect() async {}
  @override
  Future<void> playDismiss() async {}
}

/// Controllable rewarded-ad fake. `nextShowResult` controls what `show()`
/// resolves to; defaults to "reward earned" since most revive tests want
/// a successful ad.
class _FakeAdProvider implements RewardedAdProvider {
  bool nextShowResult = true;
  int preloadCalls = 0;
  int showCalls = 0;

  @override
  void preload() => preloadCalls++;

  @override
  Future<bool> show() async {
    showCalls++;
    return nextShowResult;
  }
}

/// In-memory fakes so tests never touch real sqflite/shared_preferences.
class _FakeSettingsStore extends SettingsStore {
  SavedGame? saved;

  @override
  Future<SavedGame?> getSavedGame() async => saved;

  @override
  Future<void> setSavedGame(SavedGame? game) async => saved = game;
}

/// Simulates a persistence failure (e.g. disk full) on every save.
class _ThrowingSettingsStore extends SettingsStore {
  @override
  Future<SavedGame?> getSavedGame() async => null;

  @override
  Future<void> setSavedGame(SavedGame? game) async {
    throw Exception('simulated disk failure');
  }
}

class _FakeGameHistoryDao extends GameHistoryDao {
  final List<GameRecord> records = [];

  @override
  Future<int> insert(GameRecord record) async {
    records.add(record);
    return records.length;
  }

  @override
  Future<List<GameRecord>> getAll() async => records;

  @override
  Future<int?> getBestTime(Difficulty difficulty) async => null;

  @override
  Future<void> deleteAll() async => records.clear();
}

GameController _buildController({_FakeAdProvider? adProvider}) {
  final dao = _FakeGameHistoryDao();
  return GameController(
    gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
    statsRepository: StatsRepository(dao: dao),
    soundService: _FakeSoundPlayer(),
    adProvider: adProvider ?? _FakeAdProvider(),
  );
}

SavedGame _savedGame({
  required List<List<int>> solution,
  List<List<int>>? grid,
  Map<int, Set<int>> notes = const {},
}) {
  final emptyGrid = grid ?? List.generate(9, (_) => List<int>.filled(9, 0));
  final emptyPuzzle = List.generate(9, (_) => List<int>.filled(9, 0));
  return SavedGame(
    currentGrid: emptyGrid,
    puzzle: emptyPuzzle,
    solution: solution,
    difficulty: Difficulty.easy,
    elapsedSeconds: 0,
    livesLeft: 3,
    hintsLeft: 3,
    notes: notes,
  );
}

void main() {
  test('undo restores notes cleared from the cell that was filled', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final controller = _buildController();
    await controller.resumeGame(
      _savedGame(solution: solution, notes: {0: {4, 5}}),
    );

    controller.selectCell(0, 0);
    controller.enterNumber(1); // correct placement clears (0,0)'s own notes

    expect(controller.state.currentGrid[0][0], 1);
    expect(controller.state.notes.containsKey(0), isFalse);

    controller.undo();

    expect(controller.state.currentGrid[0][0], 0);
    expect(controller.state.notes[0], {4, 5});

    controller.dispose();
  });

  test('undo restores peer notes cleared by a confirmed-correct placement',
      () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final controller = _buildController();
    // Cell (0,1) is in the same row as (0,0) and has "1" as a candidate.
    await controller.resumeGame(
      _savedGame(solution: solution, notes: {1: {1, 2}}),
    );

    controller.selectCell(0, 0);
    controller.enterNumber(1); // clears "1" from row/col/box peers' notes

    expect(controller.state.notes[1], {2});

    controller.undo();

    expect(controller.state.notes[1], {1, 2});

    controller.dispose();
  });

  test('undo restores mistake-cell tracking from before the undone move',
      () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0][0] = 5;

    final controller = _buildController();
    await controller.resumeGame(_savedGame(solution: solution));

    controller.selectCell(0, 0);
    controller.enterNumber(3); // wrong answer

    expect(controller.state.mistakeCells.contains(0), isTrue);

    controller.undo();

    expect(controller.state.mistakeCells.contains(0), isFalse);

    controller.dispose();
  });

  test('a failed background save during play does not throw unhandled',
      () async {
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _ThrowingSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
    );

    // Two unsolved cells so this move doesn't complete the grid (which
    // would route through _onGameOver's own try/catch instead of
    // _persistGame()'s).
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0][0] = 5;
    solution[0][1] = 9;
    await controller.resumeGame(_savedGame(solution: solution));

    controller.selectCell(0, 0);
    controller.enterNumber(5); // triggers _persistGame(), which now fails

    // Give the rejected save future a chance to surface if it were ever
    // left unhandled.
    await Future<void>.delayed(Duration.zero);

    controller.dispose();
  });

  test('losing the last life enters outOfLives, not lost, and does not save a record yet', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: _FakeAdProvider(),
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // wrong — solution[0][0] is 1

    expect(controller.state.phase, GamePhase.outOfLives);
    expect(controller.state.livesLeft, 0);
    expect(dao.records, isEmpty);
  });

  test('requestRevive with a successful ad restores one life and resumes play', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider()..nextShowResult = true;
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // wrong — drops to 0 lives, enters outOfLives
    expect(controller.state.phase, GamePhase.outOfLives);

    final revived = await controller.requestRevive();

    expect(revived, isTrue);
    expect(controller.state.phase, GamePhase.playing);
    expect(controller.state.livesLeft, 1);
    expect(ads.showCalls, 1);
    expect(dao.records, isEmpty);
  });

  test('requestRevive with a failed/declined ad finalizes the loss', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider()..nextShowResult = false;
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // drops to 0 lives, enters outOfLives

    final revived = await controller.requestRevive();
    await Future<void>.delayed(Duration.zero); // let _onGameOver's awaits settle

    expect(revived, isFalse);
    expect(controller.state.phase, GamePhase.lost);
    expect(dao.records, hasLength(1));
    expect(dao.records.single.won, isFalse);
  });

  test('declineRevive finalizes the loss without showing an ad', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider();
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // drops to 0 lives, enters outOfLives

    controller.declineRevive();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, GamePhase.lost);
    expect(ads.showCalls, 0);
    expect(dao.records, hasLength(1));
  });

  test('requestRevive and declineRevive are no-ops outside outOfLives', () async {
    final controller = _buildController();
    await controller.resumeGame(_savedGame(
      solution: List.generate(9, (_) => List<int>.filled(9, 0)),
    ));

    final revived = await controller.requestRevive();

    expect(revived, isFalse);
    expect(controller.state.phase, GamePhase.playing);

    controller.declineRevive();
    expect(controller.state.phase, GamePhase.playing);
  });
}
