import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/menu/widgets/best_score_card.dart';

final bestTimesProvider =
    FutureProvider.autoDispose<Map<Difficulty, int?>>((ref) async {
  return StatsRepository().getAllBestTimes();
});

final savedGameProvider = FutureProvider.autoDispose<SavedGame?>((ref) async {
  return GameRepository().loadCurrentGame();
});

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestTimesAsync = ref.watch(bestTimesProvider);
    final savedGameAsync = ref.watch(savedGameProvider);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [colors.primaryNeon, colors.accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'SUDOKU NOVA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Challenge your mind',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              _NeonButton(
                label: 'PLAY',
                color: colors.primaryNeon,
                onTap: () => context.push('/difficulty'),
              ),

              savedGameAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (saved) {
                  if (saved == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _NeonButton(
                      label:
                          'RESUME  ${saved.difficulty.displayName.toUpperCase()}',
                      color: colors.secondaryNeon,
                      onTap: () => context.go('/game?resume=true'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Text(
                    'BEST SCORES',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(height: 1, color: colors.border),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              bestTimesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: colors.primaryNeon,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, s) => Text(
                  'Could not load scores',
                  style: TextStyle(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                data: (bestTimes) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: Difficulty.values.map((d) {
                    return BestScoreCard(
                      difficulty: d,
                      bestTime: bestTimes[d],
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: _NeonButton(
                      label: 'HISTORY',
                      color: colors.accentPurple,
                      onTap: () => context.push('/history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _IconNeonButton(
                    icon: Icons.settings_rounded,
                    color: colors.textSecondary,
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}

class _IconNeonButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconNeonButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
