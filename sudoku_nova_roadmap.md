# Sudoku Nova — Flutter Android Development Roadmap

A complete, phase-by-phase plan to build a local-only Sudoku game with a menu, game history, best scores, and four difficulty levels (Easy, Medium, Hard, Impossible). No backend — everything persists on the device.

---

## 1. Tech Stack & Dependencies

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter (latest stable) + Dart | Single codebase, you already know it |
| State management | **Riverpod** (`flutter_riverpod`) | Clean, testable, no `BuildContext` headaches. Alternatives: Provider (simpler) or Bloc (more structure) |
| Persistent storage | **sqflite** for games/scores + **shared_preferences** for settings | SQL is queryable for "best score per difficulty" and sortable history. You're already comfortable with SQL from Supabase |
| Local key-value (alt) | **Hive** | If you'd rather avoid SQL entirely — type-safe, fast, less boilerplate |
| Routing | **go_router** | Declarative, clean named routes for menu → game → history |
| Time formatting | **intl** | Format timers and dates |
| Optional polish | `audioplayers` (SFX), `flutter_animate` (animations), `google_fonts` | The neon look in your mockup benefits from custom fonts + glow |

**`pubspec.yaml` core deps:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  sqflite: ^2.3.0
  path: ^1.9.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  google_fonts: ^6.2.0
  flutter_animate: ^4.5.0
  audioplayers: ^6.0.0
```

---

## 2. Project Folder Structure (feature-first + clean separation)

This keeps logic, data, and UI cleanly separated — the kind of structure that scales and reads well in a portfolio.

```
lib/
├── main.dart                       # App entry, ProviderScope, theme, router
├── app.dart                        # MaterialApp.router setup
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # Colors, neon glow, text styles
│   │   └── app_colors.dart
│   ├── constants/
│   │   └── app_constants.dart      # Grid size, max lives, hint count
│   ├── router/
│   │   └── app_router.dart         # go_router config
│   └── utils/
│       ├── duration_formatter.dart # 08:15 style formatting
│       └── date_formatter.dart
│
├── data/
│   ├── models/
│   │   ├── difficulty.dart         # enum Difficulty { easy, medium, hard, impossible }
│   │   ├── sudoku_puzzle.dart      # puzzle grid + solution + difficulty
│   │   ├── game_record.dart        # completed game (time, difficulty, date, won)
│   │   └── saved_game.dart         # in-progress game (resume support)
│   ├── datasources/
│   │   ├── database_helper.dart    # sqflite init + tables
│   │   ├── game_history_dao.dart   # CRUD for completed games
│   │   └── settings_store.dart     # shared_preferences wrapper
│   └── repositories/
│       ├── game_repository.dart    # save/load in-progress + history
│       └── stats_repository.dart   # best scores, win counts per difficulty
│
├── engine/                         # PURE Dart — no Flutter imports
│   ├── sudoku_generator.dart       # generate full board + remove cells
│   ├── sudoku_solver.dart          # backtracking solver + uniqueness check
│   ├── sudoku_validator.dart       # validate moves, check completion
│   └── difficulty_rater.dart       # clue count + technique-based grading
│
├── features/
│   ├── menu/
│   │   ├── menu_screen.dart        # title, Play, best score, history button
│   │   └── widgets/
│   │       └── best_score_card.dart
│   ├── difficulty/
│   │   └── difficulty_screen.dart  # Easy / Medium / Hard / Impossible select
│   ├── game/
│   │   ├── game_screen.dart        # board + number pad + controls + HUD
│   │   ├── controller/
│   │   │   └── game_controller.dart # Riverpod StateNotifier — game state
│   │   ├── state/
│   │   │   └── game_state.dart       # immutable game state class
│   │   └── widgets/
│   │       ├── sudoku_board.dart
│   │       ├── sudoku_cell.dart
│   │       ├── number_pad.dart
│   │       ├── game_hud.dart        # timer, lives, hint count
│   │       └── action_buttons.dart  # undo / erase / hint / notes
│   ├── history/
│   │   ├── history_screen.dart
│   │   └── widgets/
│   │       └── history_tile.dart
│   └── result/
│       └── result_screen.dart      # win/lose dialog, time, new best?
│
└── shared/
    └── widgets/
        ├── neon_button.dart
        └── glow_container.dart
```

**Rule of thumb:** the `engine/` folder must be pure Dart with zero Flutter dependencies. That means you can unit-test the entire Sudoku logic without a widget test, and even reuse it in a CLI or web build later.

---

## 3. The Sudoku Engine (the hard part — do this first)

This is the core. Get it right before touching any UI. Three pieces:

### 3.1 Solver (backtracking)
A recursive backtracking solver fills the grid by trying 1–9 in each empty cell, backtracking on conflicts. You need it for two reasons: to generate puzzles and to verify a puzzle has **exactly one solution**.

```dart
bool solve(List<List<int>> grid) {
  for (int r = 0; r < 9; r++) {
    for (int c = 0; c < 9; c++) {
      if (grid[r][c] == 0) {
        for (int n = 1; n <= 9; n++) {
          if (isValidPlacement(grid, r, c, n)) {
            grid[r][c] = n;
            if (solve(grid)) return true;
            grid[r][c] = 0; // backtrack
          }
        }
        return false; // no number fits → dead end
      }
    }
  }
  return true; // grid full
}
```

### 3.2 Generator
1. Start with an empty grid, fill it with a **valid complete solution** (run the solver on an empty grid, but shuffle the 1–9 order each cell so you get random boards).
2. Save that complete grid as the `solution`.
3. **Remove cells** one at a time. After each removal, run a solver that counts solutions — if removing a cell makes the puzzle have more than one solution, put it back. This guarantees a unique solution.
4. Keep removing until you hit the target clue count for the chosen difficulty.

### 3.3 Difficulty rating
Two-layer approach:

**Layer 1 — clue count (simple, ship this first):**

| Difficulty | Clues given (roughly) |
|---|---|
| Easy | 40–45 |
| Medium | 32–39 |
| Hard | 27–31 |
| Impossible | 22–26 (minimum solvable is 17) |

**Layer 2 — technique grading (do later for true difficulty):** Clue count alone is a weak proxy. A better rater attempts to solve the puzzle using only human techniques (naked singles, hidden singles, pointing pairs, X-wing…) and rates by which techniques are *required*. "Impossible" puzzles need advanced techniques or guessing. Build Layer 1 first, upgrade to Layer 2 once the game works end to end.

> **Performance note:** generating an "Impossible" puzzle with uniqueness checks can be slow on the main thread. Run generation inside an `Isolate` (or `compute()`) so the UI doesn't freeze. Show a quick "Generating…" state.

---

## 4. Data Models

```dart
enum Difficulty { easy, medium, hard, impossible }

class SudokuPuzzle {
  final List<List<int>> puzzle;    // 0 = empty
  final List<List<int>> solution;
  final Difficulty difficulty;
}

class GameRecord {          // a finished game → goes in history
  final int? id;
  final Difficulty difficulty;
  final int durationSeconds;
  final bool won;
  final int mistakes;
  final DateTime completedAt;
}

class SavedGame {           // in-progress game → resume support
  final List<List<int>> currentGrid;
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int livesLeft;
  final int hintsLeft;
  // optional: pencil-mark notes per cell
}
```

---

## 5. Local Storage Schema (sqflite)

**`game_history` table** — completed games:

```sql
CREATE TABLE game_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  difficulty TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  won INTEGER NOT NULL,        -- 0/1
  mistakes INTEGER NOT NULL,
  completed_at TEXT NOT NULL   -- ISO 8601
);
```

**Best score query** (fastest winning time per difficulty):

```sql
SELECT MIN(duration_seconds) FROM game_history
WHERE difficulty = ? AND won = 1;
```

**History list** (most recent first):

```sql
SELECT * FROM game_history ORDER BY completed_at DESC;
```

**`shared_preferences`** holds lightweight stuff: sound on/off, dark theme, total games played, and the serialized in-progress `SavedGame` (as a JSON string) so the player can resume after closing the app.

---

## 6. State Management (Riverpod game flow)

The `GameController` is a `StateNotifier<GameState>` that owns everything happening in a single game:

- Current grid, selected cell, selected number
- Timer (a `Stream` or periodic `Timer` ticking every second)
- Lives (hearts — your mockup shows 3), hints remaining (mockup shows 2)
- Undo stack (list of past moves)
- Pencil-mark notes mode toggle

**Move flow:** tap a cell → tap a number → controller checks against the solution. If wrong, decrement a life and flash the cell red; if lives hit 0, trigger lose. If the grid is complete and correct, stop the timer, save a `GameRecord`, check for a new best, and navigate to the result screen.

Keep `GameState` **immutable** — every change returns a `copyWith`. This makes undo trivial (just push old states) and keeps the UI rebuilds predictable.

---

## 7. Phase-by-Phase Build Plan

### ✅ Phase 0 — Setup (½ day)
- `flutter create sudoku_nova`, add dependencies, set up the folder structure above.
- Configure theme (dark navy + neon cyan/green/purple to match your mockup), fonts, and `go_router` with placeholder screens.

### ✅ Phase 1 — Engine (2–3 days) ⭐ most important
- Build and **unit-test** solver, generator, validator in the pure-Dart `engine/` folder.
- Get random unique-solution puzzle generation working for all four difficulties (Layer 1 clue counts).
- Move generation into an isolate.

### ✅ Phase 2 — Models + Storage (1 day)
- Define models, set up sqflite + DAOs + repositories.
- Test: save a fake `GameRecord`, query best score, query history.

### ✅ Phase 3 — Game Screen Core (3–4 days)
- Render the 9×9 board with thick 3×3 box borders (matching your mockup's grid).
- Number pad 1–9, cell selection, number entry.
- Wire `GameController`: timer, lives, mistake detection, win/lose.
- Undo + erase.

### ✅ Phase 4 — Menu, Difficulty, History, Result (2–3 days)
- Menu screen: title, Play button, best-score card, History button, settings.
- Difficulty selection screen (Easy/Medium/Hard/Impossible).
- History screen: list of past games with date, difficulty, time, win/loss.
- Result screen: win/lose, final time, "New best!" badge when applicable.

### ✅ Phase 5 — Game Features (2–3 days)
- Hints (reveal one correct cell, decrement hint counter).
- Pencil-mark notes mode (small candidate numbers in a cell).
- Highlight same-number cells and row/column/box of the selected cell.
- Resume in-progress game from the menu.

### ✅ Phase 6 — Polish (2–3 days)
- Neon glow styling ✅ (neon borders + box-shadow glows throughout)
- Smooth animations (`flutter_animate`) ✅ — cell number entry (scale+fade), result screen icon (elastic bounce), headline + card + buttons (staggered slide+fade).
- Sound effects + haptics ✅ — `SoundService` (audioplayers) wired to correct/wrong/win/lose; `HapticFeedback` fires on each. Drop `.mp3` files into `assets/sounds/` to activate sound (gracefully silent if missing).
- Settings screen ✅ — `/settings` route, sound on/off toggle persisted via `SharedPreferences`, Settings button in menu (gear icon next to HISTORY).
- Empty states ✅ and loading states ✅.

### ✅ Phase 7 — Testing & Release (1–2 days)
- Unit tests for engine ✅, widget tests for `SudokuBoard` and `NumberPad` ✅ (33 tests total, all passing).
- App backgrounded mid-game ✅ — handled via `WidgetsBindingObserver` in `GameScreen` + game saved to `SharedPreferences` on every move.
- Build a release APK / app bundle — run `flutter build apk --release` when ready to ship.
- App icon ✅ — neon sudoku grid icon generated (`assets/icon/app_icon.png`); `flutter_launcher_icons` applied to Android adaptive + default mipmaps.
- Splash screen ✅ — dark navy (#0D1117) background with centered grid logo; `flutter_native_splash` applied for Android (including Android 12 windowSplashScreenAnimatedIcon).

**Total: roughly 2–3 focused weeks.**

---

## 8. Key Implementation Tips

- **Test the engine in isolation first.** A bug in puzzle generation that surfaces only in the UI is painful to chase. Prove correctness with `flutter test` before building screens.
- **Immutability + `copyWith`** makes undo and state debugging dramatically easier.
- **Isolates for generation** — "Impossible" puzzles with uniqueness verification will jank the UI otherwise.
- **Separate "given" cells from "user" cells.** Givens are locked and styled differently (your mockup shows them brighter). Track which cells the player filled so erase/undo only touches user entries.
- **Save in-progress state on every move** (or on app pause via `WidgetsBindingObserver`) so a crash or close never loses a game.
- **Portfolio angle:** this pairs well with SooQna and Vault — a pure-Dart algorithmic engine with a clean architecture shows off skills those CRUD-heavy apps don't. Worth a third project page or a "more projects" entry.

---

## 9. Stretch Goals (after v1 ships)

- Daily challenge puzzle (seeded by date).
- Statistics screen: win rate, average time, streaks per difficulty.
- Auto-pencil-marks (fill all candidates).
- Multiple color themes.
- "Mistake check" toggle (some players want no mistake limit).
