# UI Sound Coverage — Sudoku Nova

## Summary
Extend the existing synthesized-tone sound system to cover three gaps: in-game cell selection / Notes toggle, the hint banner's dismissal, and navigation buttons across the non-game screens (menu, difficulty, settings, history, result). Core gameplay actions (correct/wrong/win/lose/hint/undo/erase) already have sound via `SoundService`/`ToneGenerator` — this just fills in what's silent today.

## Architecture

### `ToneGenerator` (`lib/core/services/tone_generator.dart`)
Three new cached tones, following the existing `_single(...)` builder pattern:
- `tap` — soft, brief click (~40ms). Used for one-off navigation actions (button presses, back arrows, selection chips).
- `select` — quieter and shorter (~25ms) than `tap`, since it fires on every cell tap during play — should read as a light tick, not a notification.
- `dismiss` — soft, short descending blip (~50ms) for the hint banner closing.

### `SoundService` (`lib/core/services/sound_service.dart`)
Three new methods, matching the existing pattern (haptic + tone):
```dart
Future<void> playTap() async { haptic(selectionClick); play(ToneGenerator.tap); }
Future<void> playSelect() async { haptic(selectionClick); play(ToneGenerator.select); }
Future<void> playDismiss() async { haptic(selectionClick); play(ToneGenerator.dismiss); }
```
The three new tones are added to the eager pre-generation list in the constructor, alongside the existing seven.

### Wiring

**`GameController`** (`lib/features/game/controller/game_controller.dart`):
- `selectCell()` — call `_sound.playSelect()` right after the `phase != playing` guard, covering both selecting and deselecting a cell.
- `toggleNotesMode()` — call `_sound.playSelect()` after its guard.

**`GameScreen`** (`lib/features/game/game_screen.dart`):
- `_exitToHome()` — call `SoundService().playTap()`.
- `_dismissHint()` — call `SoundService().playDismiss()`. The hint-banner auto-expiry `Timer` (currently a separate inline `setState` in the `onHint` callback) is refactored to call `_dismissHint()` instead of duplicating the clear-state logic, so the dismiss sound plays consistently whether the banner is swiped away, tapped closed, or times out.

**Non-game screens** — each screen's existing private button widgets get a `SoundService().playTap()` call added to their tap handler, immediately before invoking the existing `onTap`/`onPressed` callback. No new shared widget, no refactor of the (already duplicated) per-screen button classes — minimal diff, matching the codebase's existing pattern:
- `menu_screen.dart` — `_NeonButtonState.onTapUp` (PLAY, RESUME) and `_IconNeonButtonState.onTapUp` (settings gear), plus the HISTORY button (shares `_NeonButton`).
- `difficulty_screen.dart` — back `IconButton.onPressed`, and the difficulty-pick button's `onTapUp`.
- `settings_screen.dart` — back `IconButton.onPressed`, and the theme-mode pick (System/Light/Dark) `GestureDetector.onTap`. The sound on/off `Switch` is explicitly excluded — playing a confirmation sound for toggling sound itself is confusing UX.
- `history_screen.dart` — back `IconButton.onPressed`. (List tiles are static; no tap handler exists to wire.)
- `result_screen.dart` — both result-action buttons' `onTapUp`.

No change to `NumberPad` — its digit taps already resolve to `playCorrect`/`playWrong` via `GameController.enterNumber()`; adding a generic tap there would double up.

## Testing
This is UI/audio glue with no new branching logic to unit test (the three new `SoundService` methods are thin wrappers, consistent with the untested existing ones). Verification is manual: run the app, exercise each touch point, confirm the right tone fires once per interaction and the hint banner's three dismissal paths (swipe, tap-close, timeout) each produce exactly one `playDismiss()` call.

## Files Changed
- `lib/core/services/tone_generator.dart` — add `tap`, `select`, `dismiss`
- `lib/core/services/sound_service.dart` — add `playTap()`, `playSelect()`, `playDismiss()`; pre-warm new tones
- `lib/features/game/controller/game_controller.dart` — `playSelect()` in `selectCell()`, `toggleNotesMode()`
- `lib/features/game/game_screen.dart` — `playTap()` in `_exitToHome()`; `playDismiss()` + Timer consolidation in `_dismissHint()`
- `lib/features/menu/menu_screen.dart` — `playTap()` in both private button widgets
- `lib/features/difficulty/difficulty_screen.dart` — `playTap()` on back arrow + difficulty pick
- `lib/features/settings/settings_screen.dart` — `playTap()` on back arrow + theme-mode pick
- `lib/features/history/history_screen.dart` — `playTap()` on back arrow
- `lib/features/result/result_screen.dart` — `playTap()` on both buttons
