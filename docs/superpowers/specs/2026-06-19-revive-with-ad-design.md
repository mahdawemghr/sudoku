# Watch-an-Ad-to-Revive — Design

## Problem

When `livesLeft` hits 0, `GameController.enterNumber()` immediately sets
`phase = GamePhase.lost`, plays the lose sound, and finalizes the game
(saves the record, fires `onGameOver`, which navigates to `/result`). There
is no opportunity to continue.

We want players who run out of lives to be offered a rewarded ad: watch it,
get one life back, and keep playing. This can happen any number of times in
a single game (no per-game cap).

## Design

### 1. New phase: `GamePhase.outOfLives`

Add `outOfLives` to the `GamePhase` enum
(`lib/features/game/state/game_state.dart:4`), between "just lost the last
life" and "confirmed game over".

In `GameController.enterNumber()` (`lib/features/game/controller/game_controller.dart:183-210`),
the branch that currently fires when `newLives <= 0` changes from finalizing
the loss to entering the awaiting-decision phase:

```dart
if (newLives <= 0) {
  _sound.playWrong(); // not playLose() — the game isn't over yet
  _stopTimer();
  state = state.copyWith(
    currentGrid: newGrid,
    undoStack: newUndoStack,
    mistakeCells: newMistakes,
    notes: newNotes,
    livesLeft: 0,
    phase: GamePhase.outOfLives,
  );
  // Deliberately not persisted and not finalized here — see "Persistence" below.
}
```

Two new public controller methods drive the resolution:

```dart
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

`requestRevive()` covers both "ad watched and reward earned" and "ad
declined mid-playback / failed to show / no ad available" — all
non-reward outcomes fall through to the same `_finalizeLoss()` as
`declineRevive()`, so there's exactly one path to a confirmed loss.

Because revives are unlimited, this loop (`outOfLives` → revive →
`playing` → possibly `outOfLives` again) can repeat freely within one game.

### 2. Ad service

New dependency: `google_mobile_ads`.

`lib/core/services/rewarded_ad_service.dart` — same shape as
`SoundService`/`GameSoundPlayer` (`lib/core/services/sound_service.dart:9-21`):
an abstract `RewardedAdProvider` interface that `GameController` depends on,
and a real singleton implementation.

```dart
abstract class RewardedAdProvider {
  void preload();
  Future<bool> show(); // true = reward earned
}

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
        onAdLoaded: (ad) { _ad = ad; _loading = false; },
        onAdFailedToLoad: (_) { _loading = false; },
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
    if (ad == null) return false; // no inventory / no network — caller treats as decline
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
    ad.show(onUserEarnedReward: (_, __) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }
}
```

The reward callback always fires before the dismissed callback, and the
`isCompleted` guard means "earned" wins even though "dismissed" fires
right after — so a real reward is never overwritten by the dismiss event.

`GameController` takes a `RewardedAdProvider? adProvider` constructor param
(default `RewardedAdService()`), mirroring the existing `soundService`
param. It calls `_ads.preload()` once in `startNewGame`/`resumeGame` so an
ad is usually ready by the time it's needed; `RewardedAdService` also
re-preloads after every `show()` resolves so the next one is warming up in
the background.

`main.dart` calls `await MobileAds.instance.initialize();` once at startup,
before `runApp`.

### 3. Ad unit configuration

New file `lib/core/constants/ad_constants.dart`:

```dart
class AdConstants {
  /// Google's official Android test rewarded ad unit ID — always returns a
  /// real, functional sample ad. Replace with your production rewarded ad
  /// unit ID (from the AdMob console) before release.
  static const String reviveRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
}
```

`android/app/src/main/AndroidManifest.xml` gets the required AdMob App ID
meta-data tag (the plugin throws at runtime without it):

```xml
<!-- Google's official test App ID. Replace with your production AdMob
     App ID before release — see publish checklist. -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

Both values are Google's publicly documented test IDs — safe to commit,
and they render a real, fully-functional rewarded ad for development. The
two real values (App ID + rewarded ad unit ID) come from registering the
app inside the AdMob console tied to the user's existing publisher account
(`pub-5397163982779650`); swapping them in is a two-line change covered in
the separate publish-readiness checklist, not part of this feature's code.

### 4. UI

`lib/features/game/widgets/out_of_lives_dialog.dart` — the app's first
modal dialog, styled consistently with existing widgets (`GlowContainer`,
`NeonButton`, `colors.errorRed` accent, matching the look of
`ResultScreen`'s lose state). Content:

- A `GlowCircle` with a broken-heart icon in `errorRed`.
- Headline "Out of Lives!" and a one-line subtext explaining the offer.
- Two `NeonButton`s: **"WATCH AD · +1 LIFE"** and **"END GAME"**.
- While awaiting the ad result, the buttons are replaced with a small
  centered `CircularProgressIndicator` (local `StatefulWidget` state, not
  `GameState` — this is purely a UI loading affordance).
- Wrapped in `PopScope(canPop: false, ...)` so the hardware back button
  does nothing while it's open — the player must tap one of the two
  buttons.

`GameScreen` (`lib/features/game/game_screen.dart`) adds
`ref.listen(gameControllerProvider, ...)` inside `build()` (alongside the
existing `ref.watch`). The listener compares `previous?.phase` to
`next.phase`; when it sees the transition into `outOfLives`, it calls
`showDialog(context: context, barrierDismissible: false, builder: (_) => const OutOfLivesDialog())`.
`ref.listen` callbacks only fire once per actual state transition (not on
every rebuild), so no extra "already shown" flag is needed. The dialog's
button handlers
call `controller.requestRevive()` / `controller.declineRevive()` and then
pop themselves (`Navigator.of(context).pop()`) once the result resolves —
on revive, the player sees the board again with 1 life; on decline/no
reward, popping reveals the game screen for an instant before the existing
`onGameOver` callback navigates to `/result` (same navigation path as
today, untouched).

### 5. Persistence

The transient `outOfLives` state is **not** written to the saved-game store
(`_persistGame()` is not called from that branch). If the app is killed
while the dialog is open, resuming would otherwise reload a game frozen at
0 lives with no way to progress — by not persisting at that instant, an
app-kill mid-dialog simply loses that one in-flight game (same as any other
crash), which is an acceptable, rare edge case. Reviving successfully calls
`_persistGame()` immediately afterward as part of `requestRevive()`, so the
saved game is correct again as soon as play resumes. Declining/failing
already goes through `_finalizeLoss()` → `_onGameOver()`, which clears the
saved game exactly as it does today.

### 6. Testing

`test/features/game/controller/game_controller_test.dart` gets a
`_FakeAdProvider implements RewardedAdProvider` (controllable return value
for `show()`, no-op `preload()`), injected the same way `_FakeSoundPlayer`
is today. New cases:

- Losing the last life sets `phase == GamePhase.outOfLives` (not `lost`)
  and does not call the history DAO yet.
- `requestRevive()` with the fake returning `true` → `livesLeft == 1`,
  `phase == GamePhase.playing`, timer-driven `elapsedSeconds` keeps
  advancing (game is still live).
- `requestRevive()` with the fake returning `false` → `phase == GamePhase.lost`
  and a record is saved via the fake DAO, same as today's existing
  "loses with 0 lives" test.
- `declineRevive()` from `outOfLives` → same finalization as above.
- Calling `requestRevive()`/`declineRevive()` when `phase != outOfLives` is
  a no-op (matches the existing guard-clause pattern used by every other
  controller method).

Actual ad rendering (the real `RewardedAdService` talking to the Google
Mobile Ads SDK) can't run under `flutter test` — it needs a platform
channel — so that part is verified manually: running the app, exhausting
lives, confirming Google's test rewarded ad plays and revives correctly,
and confirming the "no ad available" path (e.g. airplane mode) falls back
to ending the game cleanly.

## Out of scope

- Any cap on revives per game (explicitly unlimited, per product decision).
- Interstitial or banner ads anywhere else in the app.
- Production AdMob App ID / ad unit ID — placeholders only; real IDs are a
  config swap covered by the separate publish-readiness checklist.
- iOS ad configuration (this project currently ships Android only — see
  `flutter_launcher_icons`/`flutter_native_splash` configs, both
  `ios: false`).
