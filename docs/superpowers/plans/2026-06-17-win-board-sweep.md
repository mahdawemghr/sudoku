# Win Board-Sweep Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the player completes the puzzle, sweep a diagonal celebration across all 81 cells (top-left → bottom-right) and delay the navigation to the result screen until the sweep finishes.

**Architecture:** `SudokuBoard._onStateChange` already detects row/col/box completions and assigns each affected cell a `celebrationStep` consumed by `SudokuCell`'s existing 450ms bounce/glow animation. Add a `justWon` branch that assigns every cell a step of `row + col` (an anti-diagonal index, 0–16) instead of the row/col/box steps, reusing the exact same per-cell animation and existing 48ms-per-step pacing unchanged. Separately, delay `GameScreen`'s win-navigation by a constant tuned to that sweep's total duration.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), existing `flutter_test` widget-test harness.

## Global Constraints

- `engine/` stays pure Dart — not touched by this plan.
- No new dependencies.
- `flutter analyze` must report no issues after every task.
- Spec: `docs/superpowers/specs/2026-06-17-win-board-sweep-design.md`.

---

### Task 1: Diagonal win-sweep stagger in `SudokuBoard`

**Files:**
- Modify: `lib/features/game/widgets/sudoku_board.dart:28-75` (`_onStateChange`)
- Test: `test/features/game/widgets/sudoku_board_test.dart`

**Interfaces:**
- Consumes: `GameState.phase` (`GamePhase` enum: `loading, playing, won, lost`, defined in `lib/features/game/state/game_state.dart:4`), `GameState.isRowComplete/isColComplete/isBoxComplete` (existing, unchanged), `SudokuCell.celebrationStep` (existing `int?` field, unchanged).
- Produces: `const Duration kWinCelebrationDelay` (top-level const in `sudoku_board.dart`), consumed by Task 2.

- [ ] **Step 1: Update the test helper to allow a custom solution grid**

In `test/features/game/widgets/sudoku_board_test.dart`, replace the existing `_playingState` helper:

```dart
GameState _playingState({List<List<int>>? grid}) {
  final g = grid ?? List.generate(9, (r) => List<int>.filled(9, 0));
  return GameState.initial().copyWith(
    currentGrid: g,
    puzzle: List.generate(9, (r) => List<int>.filled(9, 0)),
    solution: List.generate(9, (r) => List<int>.filled(9, 0)),
    phase: GamePhase.playing,
  );
}
```

with:

```dart
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
```

This is a backward-compatible signature change (new param is optional) — the three existing tests that call `_playingState()` / `_playingState(grid: grid)` are unaffected.

- [ ] **Step 2: Add an `emit` helper to `_FakeController` so tests can push new state**

In the same file, add a method to `_FakeController` (right after the constructor body):

```dart
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
```

- [ ] **Step 3: Write the failing tests**

Add these two tests at the end of `main()` in `test/features/game/widgets/sudoku_board_test.dart` (after the existing `'tapping a cell does not throw'` test):

```dart
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

    SudokuCell cellAt(int row, int col) =>
        tester.widget(find.byKey(ValueKey(row * 9 + col)));

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

    SudokuCell cellAt(int row, int col) =>
        tester.widget(find.byKey(ValueKey(row * 9 + col)));

    expect(cellAt(0, 0).celebrationStep, 0);
    expect(cellAt(3, 4).celebrationStep, 7);
    expect(cellAt(0, 8).celebrationStep, 8);
    expect(cellAt(8, 8).celebrationStep, 16);

    // Drain the per-cell staggered Future.delayed calls and the board's
    // clear timer so no pending Timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1500));
  });
```

These tests need `ProviderContainer` and `UncontrolledProviderScope`, both already available via the existing `import 'package:flutter_riverpod/flutter_riverpod.dart';` at the top of the file — no new imports required.

- [ ] **Step 4: Run the tests and confirm the win-sweep test fails**

Run: `flutter test test/features/game/widgets/sudoku_board_test.dart`

Expected: the first 4 tests (`renders 81 SudokuCell widgets`, `cells display values from currentGrid`, `tapping a cell does not throw`, `completing a row (no win) still staggers left-to-right at 48ms/step`) PASS. The new `winning the game triggers a top-left to bottom-right diagonal sweep` test FAILS — `cellAt(0, 0).celebrationStep` is `null` instead of `0`, because `_onStateChange` currently never reacts to a `phase` change, only to grid changes.

- [ ] **Step 5: Implement the win-sweep branch**

In `lib/features/game/widgets/sudoku_board.dart`, replace the `_onStateChange` method:

```dart
  void _onStateChange(GameState? prev, GameState next) {
    if (prev == null || next.isLoading || prev.isLoading) return;

    final Map<int, int> newCelebrating = {};

    // Rows — stagger left→right
    for (int r = 0; r < 9; r++) {
      if (!prev.isRowComplete(r) && next.isRowComplete(r)) {
        for (int c = 0; c < 9; c++) {
          newCelebrating[r * 9 + c] = c;
        }
      }
    }

    // Cols — stagger top→bottom
    for (int c = 0; c < 9; c++) {
      if (!prev.isColComplete(c) && next.isColComplete(c)) {
        for (int r = 0; r < 9; r++) {
          newCelebrating[r * 9 + c] = r;
        }
      }
    }

    // 3×3 boxes — stagger in reading order
    for (int b = 0; b < 9; b++) {
      if (!prev.isBoxComplete(b) && next.isBoxComplete(b)) {
        final br = (b ~/ 3) * 3;
        final bc = (b % 3) * 3;
        int step = 0;
        for (int r = br; r < br + 3; r++) {
          for (int c = bc; c < bc + 3; c++) {
            newCelebrating[r * 9 + c] = step++;
          }
        }
      }
    }

    if (newCelebrating.isEmpty) return;

    setState(() {
      _celebratingCells.addAll(newCelebrating);
    });

    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _celebratingCells.clear());
    });
  }
```

with:

```dart
  void _onStateChange(GameState? prev, GameState next) {
    if (prev == null || next.isLoading || prev.isLoading) return;

    final Map<int, int> newCelebrating = {};
    final justWon = prev.phase != GamePhase.won && next.phase == GamePhase.won;

    if (justWon) {
      // Whole-board diagonal sweep, top-left → bottom-right. This covers
      // whichever row/col/box completed on the winning move too, so the
      // row/col/box checks below are skipped entirely for this transition.
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          newCelebrating[r * 9 + c] = r + c;
        }
      }
    } else {
      // Rows — stagger left→right
      for (int r = 0; r < 9; r++) {
        if (!prev.isRowComplete(r) && next.isRowComplete(r)) {
          for (int c = 0; c < 9; c++) {
            newCelebrating[r * 9 + c] = c;
          }
        }
      }

      // Cols — stagger top→bottom
      for (int c = 0; c < 9; c++) {
        if (!prev.isColComplete(c) && next.isColComplete(c)) {
          for (int r = 0; r < 9; r++) {
            newCelebrating[r * 9 + c] = r;
          }
        }
      }

      // 3×3 boxes — stagger in reading order
      for (int b = 0; b < 9; b++) {
        if (!prev.isBoxComplete(b) && next.isBoxComplete(b)) {
          final br = (b ~/ 3) * 3;
          final bc = (b % 3) * 3;
          int step = 0;
          for (int r = br; r < br + 3; r++) {
            for (int c = bc; c < bc + 3; c++) {
              newCelebrating[r * 9 + c] = step++;
            }
          }
        }
      }
    }

    if (newCelebrating.isEmpty) return;

    setState(() {
      _celebratingCells.addAll(newCelebrating);
    });

    _clearTimer?.cancel();
    _clearTimer = Timer(
      justWon ? kWinCelebrationDelay : const Duration(milliseconds: 900),
      () {
        if (mounted) setState(() => _celebratingCells.clear());
      },
    );
  }
```

Then add the new top-level constant just above the `SudokuBoard` class declaration (after the imports, before `class SudokuBoard extends ConsumerStatefulWidget {`):

```dart
/// Total wait before the win-sweep celebration is considered finished.
/// Must stay ≥ the full sweep duration (16 diagonal steps × the existing
/// 48ms-per-step pacing in SudokuCell + its 450ms cell animation ≈ 1218ms),
/// plus a short buffer so the player sees the fully lit board before
/// GameScreen navigates to the result page.
const Duration kWinCelebrationDelay = Duration(milliseconds: 1400);
```

- [ ] **Step 6: Run the tests and confirm they all pass**

Run: `flutter test test/features/game/widgets/sudoku_board_test.dart`

Expected: all 5 tests PASS.

- [ ] **Step 7: Run the full test suite and analyzer**

Run: `flutter test && flutter analyze`

Expected: all tests pass, analyzer reports "No issues found!".

- [ ] **Step 8: Commit**

```bash
git add lib/features/game/widgets/sudoku_board.dart test/features/game/widgets/sudoku_board_test.dart
git commit -m "$(cat <<'EOF'
Add diagonal win-sweep celebration across the full board

EOF
)"
```

---

### Task 2: Delay result-screen navigation until the win sweep finishes

**Files:**
- Modify: `lib/features/game/game_screen.dart:48-57`

**Interfaces:**
- Consumes: `kWinCelebrationDelay` (`Duration`, defined in Task 1's `sudoku_board.dart`, already imported via the existing `import 'package:sudoku/features/game/widgets/sudoku_board.dart';` at `game_screen.dart:18`).

- [ ] **Step 1: Delay navigation only on a win**

In `lib/features/game/game_screen.dart`, replace:

```dart
      controller.onGameOver = (won, duration, isNewBest) {
        if (!mounted) return;
        context.go(
          '/result'
          '?won=$won'
          '&duration=$duration'
          '&difficulty=${_difficulty.label}'
          '&isNewBest=$isNewBest',
        );
      };
```

with:

```dart
      controller.onGameOver = (won, duration, isNewBest) {
        void navigate() {
          if (!mounted) return;
          context.go(
            '/result'
            '?won=$won'
            '&duration=$duration'
            '&difficulty=${_difficulty.label}'
            '&isNewBest=$isNewBest',
          );
        }

        if (!mounted) return;
        if (won) {
          Future.delayed(kWinCelebrationDelay, navigate);
        } else {
          navigate();
        }
      };
```

- [ ] **Step 2: Run the full test suite and analyzer**

Run: `flutter test && flutter analyze`

Expected: all tests pass (no test exercises this closure directly — there is no existing router-based test harness for `GameScreen` in this repo — so this step is a regression check, not new coverage), analyzer reports "No issues found!".

- [ ] **Step 3: Manually verify in the running app**

This behavior (the visible sweep + the delayed page transition) can only be confirmed by eye. If a device or emulator is available, run:

`flutter run`

Start an Easy game, fill in the final cell, and confirm:
1. A diagonal glow sweep plays from the top-left cell to the bottom-right cell across the whole board.
2. The result screen appears only after the sweep finishes (~1.4s after the last move), not immediately.
3. Losing a game (mistakes run out) still navigates to the result screen immediately, with no delay.

If no device/emulator is available in this environment, note that in the task report instead of skipping silently.

- [ ] **Step 4: Commit**

```bash
git add lib/features/game/game_screen.dart
git commit -m "$(cat <<'EOF'
Delay result-screen navigation until the win sweep finishes

EOF
)"
```
