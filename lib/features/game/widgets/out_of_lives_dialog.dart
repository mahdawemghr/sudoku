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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                textAlign: TextAlign.center,
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
