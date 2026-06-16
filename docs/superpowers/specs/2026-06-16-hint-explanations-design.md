# Hint Explanations & Difficulty-Scaled Hint Counts — Sudoku Nova

## Summary
When the player uses a hint, show *why* the revealed number is correct (Naked Single, Hidden Single, or a neutral fallback for harder logic), instead of silently filling the cell. Hint allowance also becomes difficulty-aware, mirroring the existing `maxLives` pattern: Easy 5, Medium 3, Hard 2, Impossible 1.

## Architecture

### `HintExplainer` (pure Dart, `lib/engine/hint_explainer.dart`)
New engine class, no Flutter imports, following the existing `engine/` constraint. Given `currentGrid`, `solution`, and a target `(row, col)`, it returns a `HintExplanation`:

```dart
enum HintStrategy { nakedSingle, hiddenSingleRow, hiddenSingleColumn, hiddenSingleBox, logicalDeduction }

class HintExplanation {
  final HintStrategy strategy;
  final String title;
  final String reason;
}
```

Algorithm:
1. Build a "clean" grid: any cell where `currentGrid[r][c] != solution[r][c]` is treated as empty (0). This prevents a wrong digit sitting in a peer cell from corrupting candidate calculations.
2. Compute candidates for the target cell (1–9 minus values already used in its row, column, and 3×3 box on the clean grid).
3. **Naked Single** — if exactly one candidate remains, that's the explanation: *"Every other digit already appears in this row, column, or box — N is the only number left that fits here."*
4. **Hidden Single** — else, check the box, then the row, then the column: for every other *empty* cell in that unit, is N excluded from its candidates? If so for some unit, that's a Hidden Single in that unit, with matching explanation text (*"Every other empty cell in this box already rules out N, so this is the only place left for it."*, etc.).
5. **Fallback ("Logical Deduction")** — if neither applies, return a neutral message: *"There's no simple single-step trick for this cell — N is the only digit that keeps the rest of the puzzle solvable. It would take a longer chain of reasoning to see directly."* No strategy is claimed.

Priority order (naked single → box → row → column → fallback) is fixed and deterministic — no randomness, no search for an "easier" alternate cell.

### `GameController` changes (`lib/features/game/controller/game_controller.dart`)
- New public field: `void Function(HintExplanation explanation)? onHint;` — mirrors the existing `onGameOver` callback pattern. Transient UI signal, not part of `GameState`/`SavedGame`.
- `hint()` keeps its existing target-cell selection logic unchanged (selected cell if it's a candidate, else first empty/wrong cell scanning top-left to bottom-right).
- After computing the target cell and before applying it, call `HintExplainer.explain(...)`.
- After applying the value to the grid, also set `selectedRow`/`selectedCol` to the hinted cell (new — previously hint left selection untouched). This makes the board's existing row/column/box highlight (already triggered on tap via `GameState.isHighlighted`) visually reinforce the explanation, at no extra UI cost.
- If applying the hint completes the grid, the existing win flow runs and `onHint` is **not** called — winning takes priority over showing an explanation dialog.
- Otherwise, after `_persistGame()`, call `onHint?.call(explanation)`.
- `startNewGame` reads `hintsLeft: difficulty.maxHints` instead of `AppConstants.maxHints`.

### `Difficulty` changes (`lib/data/models/difficulty.dart`)
New getter alongside `maxLives`:
```dart
int get maxHints {
  easy: 5, medium: 3, hard: 2, impossible: 1
}
```

### `AppConstants` changes (`lib/core/constants/app_constants.dart`)
`maxHints = 3` is removed — it was only referenced in the one spot now replaced by `difficulty.maxHints`.

### `HintDialog` (new, `lib/features/game/widgets/hint_dialog.dart`)
A centered modal shown via `showDialog`, styled with the existing `GlowContainer` using `colors.accentPurple` (the color already used for the hint button/HUD chip elsewhere):
- Lightbulb icon
- Strategy title (e.g. "Hidden Single (Box)", "Naked Single", "Logical Deduction")
- Reason text, phrased generically ("this row/column/box" — no numeric row/column labels, since the board has no numbered headers)
- A `NeonButton` labeled "Got it" to dismiss

### `GameScreen` wiring (`lib/features/game/game_screen.dart`)
In `initState`, alongside the existing `controller.onGameOver = ...` assignment:
```dart
controller.onHint = (explanation) {
  if (!mounted) return;
  showDialog(context: context, builder: (_) => HintDialog(explanation: explanation));
};
```

## Testing
New `test/engine/hint_explainer_test.dart` (matches existing `test/engine/*_test.dart` convention), covering:
- A constructed grid where the target cell is a Naked Single
- A constructed grid where the target cell is a Hidden Single in box / row / column (one case each)
- A constructed grid where none of the simple strategies apply → fallback `logicalDeduction`

## Files Changed
- `lib/engine/hint_explainer.dart` — new
- `test/engine/hint_explainer_test.dart` — new
- `lib/features/game/widgets/hint_dialog.dart` — new
- `lib/features/game/controller/game_controller.dart` — `onHint` callback, hint() explanation + selection, difficulty-aware `hintsLeft`
- `lib/data/models/difficulty.dart` — `maxHints` getter
- `lib/core/constants/app_constants.dart` — remove unused `maxHints`
- `lib/features/game/game_screen.dart` — wire `onHint` to `showDialog`
