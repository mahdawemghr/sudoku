# Sudoku Nova — Design Spec

**Date:** 2026-06-15
**Status:** Approved

---

## Overview

A local-only Sudoku game for Android built with Flutter. No backend. All data persists on device. Four difficulty levels: Easy, Medium, Hard, Impossible.

---

## Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (latest stable) + Dart |
| State management | Riverpod (`flutter_riverpod ^2.5.0`) |
| Persistent storage | sqflite (games/scores) + shared_preferences (settings + saved game) |
| Routing | go_router (`^14.0.0`) |
| Fonts | google_fonts (`^6.2.0`) |
| Animations | flutter_animate (`^4.5.0`) |
| Sound | audioplayers (`^6.0.0`) |
| Time/date formatting | intl (`^0.19.0`) |

All deps added upfront. audioplayers and flutter_animate unused until Phase 6.

---

## Visual Theme

Dark navy background `#0A0E1A` with neon accents:
- Cyan `#00F5FF` — primary interactive elements, selected cells
- Green `#39FF14` — correct placements, win states
- Purple `#BF00FF` — secondary accents

Typography via Google Fonts. Neon glow via `BoxShadow` with blur + spread on accent-colored containers.

---

## Folder Structure

```
lib/
├── main.dart                        # ProviderScope entry point
├── app.dart                         # MaterialApp.router
├── core/
│   ├── theme/app_theme.dart         # ThemeData, text styles, glow decorations
│   ├── theme/app_colors.dart        # Color constants
│   ├── constants/app_constants.dart # Grid size, max lives, hint count
│   ├── router/app_router.dart       # go_router config
│   └── utils/
│       ├── duration_formatter.dart
│       └── date_formatter.dart
├── data/
│   ├── models/
│   │   ├── difficulty.dart          # enum Difficulty
│   │   ├── sudoku_puzzle.dart
│   │   ├── game_record.dart
│   │   └── saved_game.dart
│   ├── datasources/
│   │   ├── database_helper.dart     # sqflite init + tables
│   │   ├── game_history_dao.dart
│   │   └── settings_store.dart
│   └── repositories/
│       ├── game_repository.dart
│       └── stats_repository.dart
├── engine/                          # Pure Dart — zero Flutter imports
│   ├── sudoku_generator.dart
│   ├── sudoku_solver.dart
│   ├── sudoku_validator.dart
│   └── difficulty_rater.dart
├── features/
│   ├── menu/menu_screen.dart
│   ├── difficulty/difficulty_screen.dart
│   ├── game/
│   │   ├── game_screen.dart
│   │   ├── controller/game_controller.dart
│   │   ├── state/game_state.dart
│   │   └── widgets/
│   │       ├── sudoku_board.dart
│   │       ├── sudoku_cell.dart
│   │       ├── number_pad.dart
│   │       ├── game_hud.dart
│   │       └── action_buttons.dart
│   ├── history/history_screen.dart
│   └── result/result_screen.dart
└── shared/widgets/
    ├── neon_button.dart
    └── glow_container.dart
```

---

## Data Models

```dart
enum Difficulty { easy, medium, hard, impossible }

class SudokuPuzzle {
  final List<List<int>> puzzle;   // 0 = empty
  final List<List<int>> solution;
  final Difficulty difficulty;
}

class GameRecord {
  final int? id;
  final Difficulty difficulty;
  final int durationSeconds;
  final bool won;
  final int mistakes;
  final DateTime completedAt;
}

class SavedGame {
  final List<List<int>> currentGrid;
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int livesLeft;
  final int hintsLeft;
}
```

---

## Storage Schema

**sqflite — `game_history` table:**
```sql
CREATE TABLE game_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  difficulty TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL,
  won INTEGER NOT NULL,
  mistakes INTEGER NOT NULL,
  completed_at TEXT NOT NULL
);
```

**shared_preferences:** sound toggle, dark theme, total games played, serialized `SavedGame` JSON for resume.

---

## Sudoku Engine

Three pure-Dart components in `engine/`:

1. **Solver** — recursive backtracking. Used to generate boards and verify unique solutions.
2. **Generator** — fill empty grid (with shuffled digit order for randomness), then remove cells one at a time while checking uniqueness. Target clue counts:
   - Easy: 40–45, Medium: 32–39, Hard: 27–31, Impossible: 22–26
3. **Validator** — check move correctness, detect completion.

Generation runs in a Dart `Isolate` (via `compute()`) to avoid UI jank, especially on Impossible difficulty.

---

## State Management

`GameController extends StateNotifier<GameState>` owns:
- Current grid, selected cell, selected number
- Timer (periodic, ticks every second)
- Lives remaining (3), hints remaining (2)
- Undo stack (list of past `GameState` snapshots)
- Notes mode toggle

`GameState` is fully immutable with `copyWith`. Every move pushes a new state.

Move flow: tap cell → tap number → validate against solution → wrong: decrement life, flash red → lives = 0: game over → grid complete: stop timer, save `GameRecord`, navigate to result.

---

## Routing

| Route | Screen |
|---|---|
| `/` | MenuScreen |
| `/difficulty` | DifficultyScreen |
| `/game` | GameScreen |
| `/history` | HistoryScreen |
| `/result` | ResultScreen |

---

## Build Phases

| Phase | Content | Est. Time |
|---|---|---|
| 0 | Setup: deps, folder structure, theme, router, placeholder screens | ½ day |
| 1 | Engine: solver, generator, validator — unit tested | 2–3 days |
| 2 | Models + storage: sqflite DAOs, repositories | 1 day |
| 3 | Game screen core: board, number pad, GameController | 3–4 days |
| 4 | Menu, difficulty, history, result screens | 2–3 days |
| 5 | Game features: hints, pencil notes, highlights, resume | 2–3 days |
| 6 | Polish: animations, SFX, settings, empty states | 2–3 days |
| 7 | Testing + release: APK, icon, splash | 1–2 days |

---

## Key Constraints

- `engine/` must have zero Flutter imports — pure Dart only
- Given cells (pre-filled) are locked and styled differently from user entries
- Save in-progress state on every move and on app pause
- Immutable `GameState` + `copyWith` throughout — enables undo and predictable rebuilds
