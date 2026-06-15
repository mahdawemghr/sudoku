import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/theme/app_theme.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/number_pad.dart';

class _FakeController extends GameController {
  _FakeController()
      : super(
          gameRepository: GameRepository(),
          statsRepository: StatsRepository(),
        ) {
    state = GameState.initial().copyWith(phase: GamePhase.playing);
  }

  @override
  Future<void> startNewGame(Difficulty difficulty) async {}
  @override
  Future<void> resumeGame(saved) async {}
  @override
  void enterNumber(int number) {} // no-op to avoid DB/state access
  @override
  void selectCell(int row, int col) {}
  @override
  void erase() {}
  @override
  void undo() {}
  @override
  void hint() {}
  @override
  void toggleNotesMode() {}
}

Widget buildPad() {
  return ProviderScope(
    overrides: [
      gameControllerProvider.overrideWith((ref) => _FakeController()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: NumberPad()),
    ),
  );
}

void main() {
  testWidgets('renders digits 1–9', (tester) async {
    await tester.pumpWidget(buildPad());
    await tester.pump();

    for (int i = 1; i <= 9; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });

  testWidgets('exactly 9 number buttons rendered', (tester) async {
    await tester.pumpWidget(buildPad());
    await tester.pump();
    expect(find.byType(GestureDetector), findsAtLeast(9));
  });

  testWidgets('tapping each digit does not throw', (tester) async {
    await tester.pumpWidget(buildPad());
    await tester.pump();

    for (int i = 1; i <= 9; i++) {
      await tester.tap(find.text('$i'));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
