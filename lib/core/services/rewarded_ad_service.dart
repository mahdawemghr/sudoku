import 'dart:async';
import 'dart:io';

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
///
/// google_mobile_ads only ships Android/iOS implementations. On any other
/// platform (e.g. running this app on Linux/Windows/macOS during desktop
/// development), every call is a no-op that behaves as "no ad available"
/// rather than touching a platform channel that doesn't exist there.
class RewardedAdService implements RewardedAdProvider {
  static final RewardedAdService _instance = RewardedAdService._();
  factory RewardedAdService() => _instance;
  RewardedAdService._();

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  RewardedAd? _ad;
  bool _loading = false;

  @override
  void preload() {
    if (!_supported) return;
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
    if (!_supported) return false;

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
      onUserEarnedReward: (_, _) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    return completer.future;
  }
}
