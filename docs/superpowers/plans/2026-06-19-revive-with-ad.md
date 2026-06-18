# Watch-an-Ad-to-Revive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a player runs out of lives, offer a rewarded ad in exchange for one more life instead of ending the game immediately. This can repeat any number of times in a single game.

**Architecture:** A new `GamePhase.outOfLives` sits between "just lost the last life" and "confirmed game over." `GameController` enters it instead of finalizing the loss, then exposes `requestRevive()` (shows a rewarded ad via an injectable `RewardedAdProvider`, revives on reward) and `declineRevive()` (finalizes the loss). `GameScreen` reacts to the phase transition via `ref.listen` and shows a callback-driven `OutOfLivesDialog` that is decoupled from the controller for testability.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), `google_mobile_ads` (new dependency), existing `flutter_test` widget/unit-test harness.

## Global Constraints

- `engine/` stays pure Dart — not touched by this plan.
- Only one new dependency: `google_mobile_ads` (resolves to `^9.0.0` as of this plan).
- `flutter analyze` must report no issues after every task.
- Ad unit IDs are Google's official test IDs only — production AdMob App ID / ad unit ID are a config swap covered by a separate publish-readiness pass, out of scope here.
- Revives are unlimited per game — no cap, no counter.
- Android only — this project currently ships `ios: false` in both `flutter_launcher_icons` and `flutter_native_splash` config (`pubspec.yaml`); no iOS ad wiring.
- Spec: `docs/superpowers/specs/2026-06-19-revive-with-ad-design.md`.

---

### Task 1: Add the Google Mobile Ads dependency and app-level wiring

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `lib/core/constants/ad_constants.dart`

**Interfaces:**
- Produces: `AdConstants.reviveRewardedAdUnitId` (`static const String`), consumed by Task 2.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add google_mobile_ads`

Expected output includes a line like `+ google_mobile_ads 9.0.0` and `pubspec.yaml`/`pubspec.lock` are updated automatically.

- [ ] **Step 2: Create the ad unit ID constant**

Create `lib/core/constants/ad_constants.dart`:

```dart
class AdConstants {
  /// Google's official Android test rewarded ad unit ID. It always serves
  /// a real, fully-functional sample ad — safe to ship during development.
  /// Replace with your production rewarded ad unit ID from the AdMob
  /// console before release.
  static const String reviveRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
}
```

- [ ] **Step 3: Declare the AdMob App ID in the Android manifest**

In `android/app/src/main/AndroidManifest.xml`, add a `<meta-data>` entry inside `<application>`, right after the existing `flutterEmbedding` meta-data block. Replace:

```xml
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
```

with:

```xml
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <!-- Google's official test AdMob App ID — always serves test ads,
             safe to ship in development. Replace with the production AdMob
             App ID from your AdMob console before release. -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>
    </application>
```

(The Google Mobile Ads plugin throws at startup if this meta-data is missing — it is mandatory, not optional.)

- [ ] **Step 4: Initialize the SDK at app startup**

In `lib/main.dart`, replace the whole file with:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite needs FFI on desktop platforms; on Android/iOS it uses native plugins.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(
      child: SudokuNovaApp(),
    ),
  );
}
```

- [ ] **Step 5: Verify nothing broke**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (same tests as before this task — nothing here is unit-testable: `MobileAds.instance.initialize()` only runs from `main()`, which no test imports; `AdConstants` is a literal; the manifest change is declarative XML).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart lib/core/constants/ad_constants.dart android/app/src/main/AndroidManifest.xml
git commit -m "$(cat <<'EOF'
Add Google Mobile Ads dependency and app-level init

EOF
)"
```

---

### Task 2: `RewardedAdProvider` interface and `RewardedAdService`

**Files:**
- Create: `lib/core/services/rewarded_ad_service.dart`

**Interfaces:**
- Consumes: `AdConstants.reviveRewardedAdUnitId` (Task 1).
- Produces: `abstract class RewardedAdProvider { void preload(); Future<bool> show(); }` and `class RewardedAdService implements RewardedAdProvider` (singleton via `factory RewardedAdService()`), both consumed by Task 3.

- [ ] **Step 1: Write the interface and implementation**

Create `lib/core/services/rewarded_ad_service.dart`:

```dart
import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:sudoku/core/constants/ad_constants.dart';

/// The rewarded-ad surface GameController depends on. Lets tests inject a
/// controllable fake instead of constructing a real RewardedAdService,
/// which talks to the Google Mobile Ads SDK over a platform channel.
abstract class RewardedAdProvider {
  /// Starts loading the next ad in the background, if one isn't already
  /// loaded or loading. Safe to call repeatedly.
  void preload();

  /// Shows the currently loaded ad (loading one first if necessary).
  /// Resolves true if the player earned the reward, false if they
  /// declined, the ad failed to show, or no ad was available in time.
  Future<bool> show();
}

/// Wraps a single rewarded ad slot from the Google Mobile Ads SDK.
class RewardedAdService implements RewardedAdProvider {
  static final RewardedAdService _instance = RewardedAdService._();
  factory RewardedAdService() => _instance;
  RewardedAdService._();

  RewardedAd? _ad;
  bool _loading = false;

  @override
  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdConstants.reviveRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  @override
  Future<bool> show() async {
    if (_ad == null) {
      preload();
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (_ad == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    final ad = _ad;
    if (ad == null) return false; // no inventory / no network in time
    _ad = null;

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (_, __) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    return completer.future;
  }
}
```

The reward callback always fires before the dismissed callback, so the
`isCompleted` guard means a real reward is never overwritten by the
dismiss event that immediately follows it.

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: `No issues found!`

There is no automated test for this file — `RewardedAd.load`/`.show` require a real platform channel, the same reason `SoundService` (the real implementation backing `GameSoundPlayer`, in `lib/core/services/sound_service.dart`) has no dedicated unit test either. `RewardedAdProvider`, the interface, is what gets exercised by fakes in Task 3's tests.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/rewarded_ad_service.dart
git commit -m "$(cat <<'EOF'
Add RewardedAdProvider interface and RewardedAdService

EOF
)"
```

---

### Task 3: `GameController` — `outOfLives` phase, `requestRevive`, `declineRevive`

**Files:**
- Modify: `lib/features/game/state/game_state.dart:4`
- Modify: `lib/features/game/controller/game_controller.dart`
- Modify: `test/features/game/controller/game_controller_test.dart`

**Interfaces:**
- Consumes: `RewardedAdProvider` (Task 2).
- Produces: `GamePhase.outOfLives` (enum value), `GameController.requestRevive()` (`Future<bool> Function()`), `GameController.declineRevive()` (`void Function()`) — both consumed by Task 5. `GameController`'s constructor gains an optional `RewardedAdProvider? adProvider` param, mirroring the existing `GameSoundPlayer? soundService` param.

- [ ] **Step 1: Add the new phase**

In `lib/features/game/state/game_state.dart`, replace:

```dart
enum GamePhase { loading, playing, won, lost }
```

with:

```dart
enum GamePhase { loading, playing, outOfLives, won, lost }
```

- [ ] **Step 2: Add a fake ad provider and write the failing tests**

In `test/features/game/controller/game_controller_test.dart`, add this import alongside the existing ones at the top:

```dart
import 'package:sudoku/core/services/rewarded_ad_service.dart';
```

Add this class right after `_FakeSoundPlayer` (before `_FakeSettingsStore`):

```dart
/// Controllable rewarded-ad fake. `nextShowResult` controls what `show()`
/// resolves to; defaults to "reward earned" since most revive tests want
/// a successful ad.
class _FakeAdProvider implements RewardedAdProvider {
  bool nextShowResult = true;
  int preloadCalls = 0;
  int showCalls = 0;

  @override
  void preload() => preloadCalls++;

  @override
  Future<bool> show() async {
    showCalls++;
    return nextShowResult;
  }
}
```

Change `_buildController` to accept and wire a fake ad provider:

```dart
GameController _buildController({_FakeAdProvider? adProvider}) {
  final dao = _FakeGameHistoryDao();
  return GameController(
    gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
    statsRepository: StatsRepository(dao: dao),
    soundService: _FakeSoundPlayer(),
    adProvider: adProvider ?? _FakeAdProvider(),
  );
}
```

Add these tests at the end of `main()`:

```dart
  test('losing the last life enters outOfLives, not lost, and does not save a record yet', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: _FakeAdProvider(),
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // wrong — solution[0][0] is 1

    expect(controller.state.phase, GamePhase.outOfLives);
    expect(controller.state.livesLeft, 0);
    expect(dao.records, isEmpty);
  });

  test('requestRevive with a successful ad restores one life and resumes play', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider()..nextShowResult = true;
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // wrong — drops to 0 lives, enters outOfLives
    expect(controller.state.phase, GamePhase.outOfLives);

    final revived = await controller.requestRevive();

    expect(revived, isTrue);
    expect(controller.state.phase, GamePhase.playing);
    expect(controller.state.livesLeft, 1);
    expect(ads.showCalls, 1);
    expect(dao.records, isEmpty);
  });

  test('requestRevive with a failed/declined ad finalizes the loss', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider()..nextShowResult = false;
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // drops to 0 lives, enters outOfLives

    final revived = await controller.requestRevive();
    await Future<void>.delayed(Duration.zero); // let _onGameOver's awaits settle

    expect(revived, isFalse);
    expect(controller.state.phase, GamePhase.lost);
    expect(dao.records, hasLength(1));
    expect(dao.records.single.won, isFalse);
  });

  test('declineRevive finalizes the loss without showing an ad', () async {
    final solution = List.generate(9, (_) => List<int>.filled(9, 0));
    solution[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    final ads = _FakeAdProvider();
    final dao = _FakeGameHistoryDao();
    final controller = GameController(
      gameRepository: GameRepository(dao: dao, store: _FakeSettingsStore()),
      statsRepository: StatsRepository(dao: dao),
      soundService: _FakeSoundPlayer(),
      adProvider: ads,
    );
    final saved = _savedGame(solution: solution);
    await controller.resumeGame(SavedGame(
      currentGrid: saved.currentGrid,
      puzzle: saved.puzzle,
      solution: saved.solution,
      difficulty: saved.difficulty,
      elapsedSeconds: saved.elapsedSeconds,
      livesLeft: 1,
      hintsLeft: saved.hintsLeft,
      notes: saved.notes,
    ));

    controller.selectCell(0, 0);
    controller.enterNumber(9); // drops to 0 lives, enters outOfLives

    controller.declineRevive();
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, GamePhase.lost);
    expect(ads.showCalls, 0);
    expect(dao.records, hasLength(1));
  });

  test('requestRevive and declineRevive are no-ops outside outOfLives', () async {
    final controller = _buildController();
    await controller.resumeGame(_savedGame(
      solution: List.generate(9, (_) => List<int>.filled(9, 0)),
    ));

    final revived = await controller.requestRevive();

    expect(revived, isFalse);
    expect(controller.state.phase, GamePhase.playing);

    controller.declineRevive();
    expect(controller.state.phase, GamePhase.playing);
  });
```

- [ ] **Step 3: Run the tests and confirm they fail to compile**

Run: `flutter test test/features/game/controller/game_controller_test.dart`

Expected: compile error — `GameController` has no `adProvider` parameter, no `requestRevive`/`declineRevive` methods, and `GamePhase.outOfLives` doesn't exist as a controller-reachable state yet.

- [ ] **Step 4: Implement the controller changes**

In `lib/features/game/controller/game_controller.dart`, add the import:

```dart
import 'package:sudoku/core/services/rewarded_ad_service.dart';
```

Replace the field declarations and constructor:

```dart
  int _totalMistakes = 0;
  final GameSoundPlayer _sound;

  GameController({
    required GameRepository gameRepository,
    required StatsRepository statsRepository,
    GameSoundPlayer? soundService,
  })  : _gameRepository = gameRepository,
        _statsRepository = statsRepository,
        _sound = soundService ?? SoundService(),
        super(GameState.initial()) {
    // Warm the database connection while the user is on the game loading screen
    // so the first game-over DB write is instant.
    _statsRepository.getBestTime(Difficulty.easy).ignore();
  }
```

with:

```dart
  int _totalMistakes = 0;
  final GameSoundPlayer _sound;
  final RewardedAdProvider _ads;

  GameController({
    required GameRepository gameRepository,
    required StatsRepository statsRepository,
    GameSoundPlayer? soundService,
    RewardedAdProvider? adProvider,
  })  : _gameRepository = gameRepository,
        _statsRepository = statsRepository,
        _sound = soundService ?? SoundService(),
        _ads = adProvider ?? RewardedAdService(),
        super(GameState.initial()) {
    // Warm the database connection while the user is on the game loading screen
    // so the first game-over DB write is instant.
    _statsRepository.getBestTime(Difficulty.easy).ignore();
  }
```

In `startNewGame`, add a preload call right before `_startTimer();`:

```dart
    _startTimer();
    _persistGame(); // Save immediately so resume works even before the first move.
```

becomes:

```dart
    _ads.preload();
    _startTimer();
    _persistGame(); // Save immediately so resume works even before the first move.
```

In `resumeGame`, add the same preload call right before its `_startTimer();`:

```dart
    _startTimer();
  }

  void selectCell(int row, int col) {
```

becomes:

```dart
    _ads.preload();
    _startTimer();
  }

  void selectCell(int row, int col) {
```

Replace the losing branch inside `enterNumber`:

```dart
      final newLives = state.livesLeft - 1;
      if (newLives <= 0) {
        _sound.playLose();
        _stopTimer();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          notes: newNotes,
          livesLeft: 0,
          phase: GamePhase.lost,
        );
        _onGameOver(won: false);
      } else {
```

with:

```dart
      final newLives = state.livesLeft - 1;
      if (newLives <= 0) {
        _sound.playWrong(); // not playLose() — the player may still revive
        _stopTimer();
        state = state.copyWith(
          currentGrid: newGrid,
          undoStack: newUndoStack,
          mistakeCells: newMistakes,
          notes: newNotes,
          livesLeft: 0,
          phase: GamePhase.outOfLives,
        );
      } else {
```

Add the two new public methods and a private helper right after `resumeTimer()` (before the `// Private helpers` divider):

```dart
  void resumeTimer() {
    if (!_timerRunning && state.phase == GamePhase.playing) _startTimer();
  }

  /// Shows a rewarded ad and, if the player earns the reward, revives them
  /// with one life and resumes play. Otherwise finalizes the loss exactly
  /// like `declineRevive()`. No-op (returns false) outside `outOfLives`.
  Future<bool> requestRevive() async {
    if (state.phase != GamePhase.outOfLives) return false;
    final earned = await _ads.show();
    if (!mounted) return false;
    if (earned) {
      state = state.copyWith(livesLeft: 1, phase: GamePhase.playing);
      _startTimer();
      _persistGame();
      return true;
    }
    _finalizeLoss();
    return false;
  }

  /// Ends the game without showing an ad. No-op outside `outOfLives`.
  void declineRevive() {
    if (state.phase != GamePhase.outOfLives) return;
    _finalizeLoss();
  }

  void _finalizeLoss() {
    _sound.playLose();
    state = state.copyWith(phase: GamePhase.lost);
    _onGameOver(won: false);
  }
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `flutter test test/features/game/controller/game_controller_test.dart`
Expected: all tests PASS, including the five new ones.

- [ ] **Step 6: Run the full suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add lib/features/game/state/game_state.dart lib/features/game/controller/game_controller.dart test/features/game/controller/game_controller_test.dart
git commit -m "$(cat <<'EOF'
Add outOfLives phase with ad-revive controller logic

EOF
)"
```

---

### Task 4: `OutOfLivesDialog` widget

**Files:**
- Create: `lib/features/game/widgets/out_of_lives_dialog.dart`
- Test: `test/features/game/widgets/out_of_lives_dialog_test.dart`

**Interfaces:**
- Consumes: `GlowContainer`, `GlowCircle` (`lib/shared/widgets/glow_container.dart`), `NeonButton` (`lib/shared/widgets/neon_button.dart`), `context.appColors` (`lib/core/theme/app_colors.dart`) — all existing, unchanged.
- Produces: `OutOfLivesDialog({required Future<bool> Function() onWatchAd, required VoidCallback onEndGame})`, consumed by Task 5. Deliberately has no dependency on `GameController` or any provider — purely callback-driven for isolated testability.

- [ ] **Step 1: Write the failing tests**

Create `test/features/game/widgets/out_of_lives_dialog_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/theme/app_theme.dart';
import 'package:sudoku/features/game/widgets/out_of_lives_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  required Future<bool> Function() onWatchAd,
  required VoidCallback onEndGame,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => OutOfLivesDialog(
                onWatchAd: onWatchAd,
                onEndGame: onEndGame,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the headline and both action buttons', (tester) async {
    await _openDialog(
      tester,
      onWatchAd: () async => true,
      onEndGame: () {},
    );

    expect(find.text('Out of Lives!'), findsOneWidget);
    expect(find.text('WATCH AD · +1 LIFE'), findsOneWidget);
    expect(find.text('END GAME'), findsOneWidget);
  });

  testWidgets('tapping End Game calls onEndGame and closes the dialog',
      (tester) async {
    var endGameCalled = false;

    await _openDialog(
      tester,
      onWatchAd: () async => true,
      onEndGame: () => endGameCalled = true,
    );

    await tester.tap(find.text('END GAME'));
    await tester.pumpAndSettle();

    expect(endGameCalled, isTrue);
    expect(find.text('Out of Lives!'), findsNothing);
  });

  testWidgets(
      'tapping Watch Ad shows a loading indicator, then calls onWatchAd and closes',
      (tester) async {
    final completer = Completer<bool>();
    var watchAdCalled = false;

    await _openDialog(
      tester,
      onWatchAd: () {
        watchAdCalled = true;
        return completer.future;
      },
      onEndGame: () {},
    );

    await tester.tap(find.text('WATCH AD · +1 LIFE'));
    await tester.pump();

    expect(watchAdCalled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('WATCH AD · +1 LIFE'), findsNothing);

    completer.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Out of Lives!'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `flutter test test/features/game/widgets/out_of_lives_dialog_test.dart`
Expected: compile error — `package:sudoku/features/game/widgets/out_of_lives_dialog.dart` doesn't exist yet.

- [ ] **Step 3: Implement the dialog**

Create `lib/features/game/widgets/out_of_lives_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/shared/widgets/glow_container.dart';
import 'package:sudoku/shared/widgets/neon_button.dart';

/// Modal shown when the player runs out of lives, offering a rewarded ad
/// in exchange for one more life. Purely callback-driven — it has no
/// dependency on GameController or any provider, so it's testable in
/// isolation and reusable if the revive offer is ever needed elsewhere.
class OutOfLivesDialog extends StatefulWidget {
  /// Requests the ad be shown; resolves true if the player earned the
  /// reward (and should be revived), false otherwise.
  final Future<bool> Function() onWatchAd;

  /// Called when the player chooses to end the game instead.
  final VoidCallback onEndGame;

  const OutOfLivesDialog({
    super.key,
    required this.onWatchAd,
    required this.onEndGame,
  });

  @override
  State<OutOfLivesDialog> createState() => _OutOfLivesDialogState();
}

class _OutOfLivesDialogState extends State<OutOfLivesDialog> {
  bool _loading = false;

  Future<void> _watchAd() async {
    setState(() => _loading = true);
    await widget.onWatchAd();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _endGame() {
    widget.onEndGame();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GlowContainer(
          glowColor: colors.errorRed,
          backgroundColor: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.errorRed.withValues(alpha: 0.5),
            width: 1.5,
          ),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlowCircle(
                icon: Icons.heart_broken_rounded,
                color: colors.errorRed,
                size: 80,
                iconSize: 42,
              ),
              const SizedBox(height: 20),
              Text(
                'Out of Lives!',
                style: TextStyle(
                  color: colors.errorRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Watch a short ad to get one more life and keep playing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(
                    color: colors.primaryNeon,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                NeonButton(
                  label: 'WATCH AD · +1 LIFE',
                  color: colors.secondaryNeon,
                  onTap: _watchAd,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'END GAME',
                  color: colors.textSecondary,
                  onTap: _endGame,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `flutter test test/features/game/widgets/out_of_lives_dialog_test.dart`
Expected: all 3 tests PASS.

- [ ] **Step 5: Run the full suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/game/widgets/out_of_lives_dialog.dart test/features/game/widgets/out_of_lives_dialog_test.dart
git commit -m "$(cat <<'EOF'
Add OutOfLivesDialog widget

EOF
)"
```

---

### Task 5: Wire the dialog into `GameScreen`

**Files:**
- Modify: `lib/features/game/game_screen.dart`

**Interfaces:**
- Consumes: `GamePhase.outOfLives`, `GameController.requestRevive`, `GameController.declineRevive` (Task 3); `OutOfLivesDialog` (Task 4).

- [ ] **Step 1: Add the import**

In `lib/features/game/game_screen.dart`, add to the existing import block (alphabetical, after the `number_pad.dart` import and before `sudoku_board.dart`):

```dart
import 'package:sudoku/features/game/widgets/out_of_lives_dialog.dart';
```

- [ ] **Step 2: React to the phase transition**

Replace the start of `build`:

```dart
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final colors = context.appColors;

    return PopScope(
```

with:

```dart
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final colors = context.appColors;

    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      final justRanOut = previous?.phase != GamePhase.outOfLives &&
          next.phase == GamePhase.outOfLives;
      if (!justRanOut) return;

      final controller = ref.read(gameControllerProvider.notifier);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OutOfLivesDialog(
          onWatchAd: controller.requestRevive,
          onEndGame: controller.declineRevive,
        ),
      );
    });

    return PopScope(
```

- [ ] **Step 3: Run the full suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass (there is no existing router-based widget-test harness for `GameScreen` in this repo — `startNewGame` runs real puzzle generation via `compute()`, which existing tests avoid entirely — so this is a regression check, not new coverage). `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/game/game_screen.dart
git commit -m "$(cat <<'EOF'
Show OutOfLivesDialog when the player runs out of lives

EOF
)"
```

---

### Task 6: Manual end-to-end verification

This task has no code changes — it confirms the real Google Mobile Ads SDK behavior, which cannot run under `flutter test` (no platform channel).

- [ ] **Step 1: Run the app on a connected device or emulator**

Run: `flutter run`

- [ ] **Step 2: Verify the revive path**

Start an Impossible-difficulty game (1 life, so the dialog appears on the very first mistake) and enter a wrong number. Confirm:
1. The `OutOfLivesDialog` appears with the broken-heart icon, headline, and both buttons.
2. The hardware/gesture back button does nothing while it's open.
3. Tapping **WATCH AD · +1 LIFE** shows the loading spinner, then Google's test rewarded ad plays full-screen.
4. Watching the test ad to completion closes the dialog, restores 1 life in the HUD, and the timer/board are interactive again.

- [ ] **Step 3: Verify the decline path**

Run out of lives again. Tap **END GAME**. Confirm the dialog closes and the Result screen appears with "Game Over", same as before this feature existed.

- [ ] **Step 4: Verify the no-ad-available fallback**

Enable airplane mode (or otherwise disable network), run out of lives, and tap **WATCH AD · +1 LIFE**. Confirm that after the loading spinner, since no ad can load, the dialog closes and the game ends cleanly (Result screen, "Game Over") rather than hanging or crashing.

- [ ] **Step 5: Verify repeatability**

With network restored, confirm reviving twice in the same game both work (unlimited revives) — run out of lives, revive, run out again, revive again.

- [ ] **Step 6: Report results**

If a device/emulator isn't available in this environment, note that explicitly rather than skipping silently — this task must be completed before the feature can be considered done.
