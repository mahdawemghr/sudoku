# Win Board-Sweep Animation — Design

## Problem

When a row, column, or 3×3 box is completed, `SudokuCell` plays a scale-bounce
+ glow celebration that staggers across the affected cells. When the player
wins the entire puzzle, no equivalent celebration plays — `GameController`
navigates straight to `/result` the instant the grid is filled correctly.

The win should get its own celebration: a diagonal sweep across all 81 cells,
top-left to bottom-right, and the result page must wait for the sweep to
finish before appearing.

## Design

### 1. Trigger & detection

`SudokuBoard._onStateChange` (`lib/features/game/widgets/sudoku_board.dart:28`)
already compares `prev`/`next` `GameState` to detect row/col/box completions
and assign each affected cell a `celebrationStep`. Add a check at the top of
that method:

```dart
final justWon = prev.phase != GamePhase.won && next.phase == GamePhase.won;
```

When `justWon` is true, skip the existing row/col/box stagger loops entirely
and instead assign every cell a step based on its anti-diagonal index:

```dart
for (int r = 0; r < 9; r++) {
  for (int c = 0; c < 9; c++) {
    newCelebrating[r * 9 + c] = r + c; // 0..16
  }
}
```

This produces a sweep where all cells on the same diagonal animate together,
moving from the top-left corner to the bottom-right corner. It also
naturally covers whichever row/col/box completed on the winning move, so
there's no risk of two staggers firing over each other on the same frame.

### 2. Per-cell animation (reused as-is)

`SudokuCell`'s existing celebration `AnimationController` (450ms scale-bounce
+ glow TweenSequence, `lib/features/game/widgets/sudoku_cell.dart:75-89`) is
reused unchanged — same visual treatment as row/col/box completions, just
triggered across the whole board.

The only change to `SudokuCell` is making the per-step delay multiplier
configurable. Today `didUpdateWidget` hardcodes `widget.celebrationStep! * 48`
(48ms per step). Add a `celebrationStepMs` field (default `48`) so
`SudokuBoard` can pass a different pace for the win sweep:

```dart
final delay = widget.celebrationStep! * widget.celebrationStepMs;
```

### 3. Win sweep pacing

`SudokuBoard` passes `celebrationStepMs: 55` when rendering cells during a
win sweep (vs. the default 48 for row/col/box). With 17 diagonal steps
(0–16), the last diagonal starts at 16×55=880ms and finishes its 450ms
animation at ~1330ms.

A constant captures the total wait the result page must honor:

```dart
/// Must stay ≥ the full sweep duration (16 steps × 55ms + 450ms cell
/// animation ≈ 1330ms), plus a short buffer so the player sees the fully
/// lit board before the page transitions.
const Duration kWinCelebrationDelay = Duration(milliseconds: 1500);
```

Defined alongside the other board-celebration constants in
`sudoku_board.dart` and exported for `game_screen.dart` to use (already
imports this file).

### 4. Delaying navigation

`GameScreen`'s `onGameOver` callback
(`lib/features/game/game_screen.dart:48-57`) currently calls `context.go(...)`
immediately. Change it to delay only the win case:

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

`GameController` and its background DB save (`_onGameOver`,
`game_controller.dart:434-467`) are untouched — the save still happens
immediately in the background while the sweep plays on screen; only the
page transition waits.

### 5. Edge cases

- **Loss path** (`GamePhase.lost`) is unaffected — `won == false` navigates
  immediately as today.
- **Screen disposal**: the existing `mounted` check inside the (now delayed)
  navigation closure prevents a crash if the player backs out during the
  delay.
- No `engine/` changes. No new tests required — this is a pure UI/animation
  change to existing widgets; `flutter analyze` and the current test suite
  must still pass.

## Out of scope

- Confetti, sound changes, or any effect beyond the existing cell
  bounce/glow.
- Changing the row/col/box celebration behavior or timing.
