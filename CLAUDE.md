# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                                          # run on connected device/emulator
flutter test                                         # run all tests
flutter test test/engine/sudoku_solver_test.dart     # run a single test file
flutter analyze                                      # lint
flutter build apk                                    # release Android build
```

## Architecture

**Sudoku Nova** is a local-only Flutter Sudoku game. No backend — all persistence is on-device via sqflite and shared_preferences.

### Layer separation

```
engine/          ← pure Dart only, zero Flutter imports — unit-testable in isolation
data/            ← models, DAOs, repositories (sqflite + shared_preferences)
features/        ← UI screens and widgets, one folder per screen
core/            ← theme, router, constants, formatters
```

The `engine/` constraint is strict: `sudoku_generator.dart`, `sudoku_solver.dart`, `sudoku_validator.dart`, and `difficulty_rater.dart` must never import Flutter. This keeps the logic reusable and fast to test.

### State management

Riverpod is used throughout. The central provider is `gameControllerProvider` (`StateNotifierProvider.autoDispose`) in `lib/features/game/controller/game_controller.dart`. `GameState` is fully immutable — every mutation returns a `copyWith`. The undo stack is a `List<List<List<int>>>` of grid snapshots pushed before each move.

### Puzzle generation

`SudokuGenerator.generatePuzzleIsolate` is the `compute()`-compatible entry point called from `GameController.startNewGame`. Generation runs on a background isolate to avoid blocking the UI during the uniqueness-check loop (especially for "Impossible" difficulty).

### Routing

Routes are defined in `lib/core/router/app_router.dart` using go_router. Data is passed between screens via URI query parameters (e.g. `?difficulty=hard&won=true`). Route constants live in `AppRoutes`.

### Storage

- **sqflite** (`database_helper.dart`) holds a `game_history` table for completed games. Best score queries use `MIN(duration_seconds) WHERE won = 1 AND difficulty = ?`.
- **shared_preferences** (`settings_store.dart`) holds sound/theme toggles and the serialized in-progress `SavedGame` JSON for resume support.

### Difficulty levels

`Difficulty` enum (in `data/models/difficulty.dart`) maps to `EngineGivenDifficulty` (in `engine/difficulty_rater.dart`) via `.toEngine()`. Clue counts: Easy 40–45, Medium 32–39, Hard 27–31, Impossible 22–26.
