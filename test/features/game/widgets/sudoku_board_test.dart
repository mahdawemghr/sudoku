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

GameState _playingState({List<List<int>>? grid}) {
  final g = grid ?? List.generate(9, (r) => List<int>.filled(9, 0));
  return GameState.initial().copyWith(
    currentGrid: g,
    puzzle: List.generate(9, (r) => List<int>.filled(9, 0)),
    solution: List.generate(9, (r) => List<int>.filled(9, 0)),
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
}
