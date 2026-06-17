import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/theme/app_theme.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/sudoku_board.dart';
import 'package:sudoku/features/game/widgets/sudoku_cell.dart';

/// A no-op GameController for widget tests — never touches the DB or isolates.
class _FakeController extends GameController {
  _FakeController(GameState initial)
      : super(
          gameRepository: GameRepository(),
          statsRepository: StatsRepository(),
        ) {
    state = initial;
  }

  /// Test-only hook: StateNotifier's `state` setter is `@protected`, so
  /// expose a public way for tests to push a new state and trigger
  /// SudokuBoard's `ref.listen` callback.
  void emit(GameState next) => state = next;

  @override
  Future<void> startNewGame(Difficulty difficulty) async {}
  @override
  Future<void> resumeGame(saved) async {}
  @override
  void selectCell(int row, int col) {}
  @override
  void enterNumber(int number) {}
  @override
  void erase() {}
  @override
  void undo() {}
  @override
  void hint() {}
  @override
  void toggleNotesMode() {}
}

GameState _playingState({
  List<List<int>>? grid,
  List<List<int>>? solution,
}) {
  final g = grid ?? List.generate(9, (r) => List<int>.filled(9, 0));
  final sol = solution ?? List.generate(9, (r) => List<int>.filled(9, 0));
  return GameState.initial().copyWith(
    currentGrid: g,
    puzzle: List.generate(9, (r) => List<int>.filled(9, 0)),
    solution: sol,
    phase: GamePhase.playing,
  );
}

Widget buildBoard(GameState state) {
  return ProviderScope(
    overrides: [
      gameControllerProvider.overrideWith((ref) => _FakeController(state)),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: SudokuBoard()),
    ),
  );
}

void main() {
  // The board sizes itself to its width, so give the test a square viewport.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders 81 SudokuCell widgets', (tester) async {
    tester.view.physicalSize = const Size(1080, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildBoard(_playingState()));
    await tester.pump();
    expect(find.byType(SudokuCell), findsNWidgets(81));
  });

  testWidgets('cells display values from currentGrid', (tester) async {
    tester.view.physicalSize = const Size(1080, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final grid = List.generate(9, (r) => List<int>.filled(9, 0));
    grid[0][0] = 5;
    grid[4][4] = 9;

    await tester.pumpWidget(buildBoard(_playingState(grid: grid)));
    await tester.pumpAndSettle(); // drain flutter_animate timers

    expect(find.text('5'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('tapping a cell does not throw', (tester) async {
    tester.view.physicalSize = const Size(1080, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildBoard(_playingState()));
    await tester.pump();

    final cells = find.byType(SudokuCell);
    await tester.tap(cells.first);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'completing a row (no win) still staggers left-to-right at 48ms/step',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final solution = List.generate(9, (r) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final almostRow = List.generate(9, (r) => List<int>.filled(9, 0));
    almostRow[0] = [1, 2, 3, 4, 5, 6, 7, 8, 0];

    final container = ProviderContainer(overrides: [
      gameControllerProvider.overrideWith(
        (ref) =>
            _FakeController(_playingState(grid: almostRow, solution: solution)),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: SudokuBoard()),
        ),
      ),
    );
    await tester.pump();

    final controller =
        container.read(gameControllerProvider.notifier) as _FakeController;
    final completedRow =
        List.generate(9, (r) => List<int>.from(almostRow[r]));
    completedRow[0][8] = 9;
    controller.emit(controller.state.copyWith(currentGrid: completedRow));
    await tester.pump();

    // SudokuCell is keyed by cell index, but its inner digit Text is keyed
    // by displayed value — both are plain ValueKey<int>, so a bare
    // find.byKey can collide when an index matches another cell's digit.
    // Restrict the match to SudokuCell itself.
    SudokuCell cellAt(int row, int col) => tester.widget<SudokuCell>(
          find.byWidgetPredicate(
            (w) => w is SudokuCell && w.key == ValueKey(row * 9 + col),
          ),
        );

    expect(cellAt(0, 0).celebrationStep, 0);
    expect(cellAt(0, 8).celebrationStep, 8);
    expect(cellAt(1, 0).celebrationStep, isNull);

    // Drain the per-cell staggered Future.delayed calls and the board's
    // clear timer so no pending Timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets(
      'winning the game triggers a top-left to bottom-right diagonal sweep',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(overrides: [
      gameControllerProvider.overrideWith(
        (ref) => _FakeController(_playingState()),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: SudokuBoard()),
        ),
      ),
    );
    await tester.pump();

    final controller =
        container.read(gameControllerProvider.notifier) as _FakeController;
    controller.emit(controller.state.copyWith(phase: GamePhase.won));
    await tester.pump();

    // SudokuCell is keyed by cell index, but its inner digit Text is keyed
    // by displayed value — both are plain ValueKey<int>, so a bare
    // find.byKey can collide when an index matches another cell's digit.
    // Restrict the match to SudokuCell itself.
    SudokuCell cellAt(int row, int col) => tester.widget<SudokuCell>(
          find.byWidgetPredicate(
            (w) => w is SudokuCell && w.key == ValueKey(row * 9 + col),
          ),
        );

    expect(cellAt(0, 0).celebrationStep, 0);
    expect(cellAt(3, 4).celebrationStep, 7);
    expect(cellAt(0, 8).celebrationStep, 8);
    expect(cellAt(8, 8).celebrationStep, 16);

    // Drain the per-cell staggered Future.delayed calls and the board's
    // clear timer so no pending Timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
