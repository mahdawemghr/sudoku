import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/menu/widgets/best_score_card.dart';

final bestTimesProvider = FutureProvider<Map<Difficulty, int?>>((ref) async {
  return StatsRepository().getAllBestTimes();
});

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestTimesAsync = ref.watch(bestTimesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // App title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primaryNeon, AppColors.accentPurple],
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
              const Text(
                'Challenge your mind',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 56),
              // PLAY button
              _NeonButton(
                label: 'PLAY',
                color: AppColors.primaryNeon,
                onTap: () => context.push('/difficulty'),
              ),
              const SizedBox(height: 48),
              // Best scores section
              Row(
                children: [
                  const Text(
                    'BEST SCORES',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              bestTimesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryNeon,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => const Text(
                  'Could not load scores',
                  style: TextStyle(color: AppColors.textSecondary),
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
              // HISTORY button
              _NeonButton(
                label: 'HISTORY',
                color: AppColors.accentPurple,
                onTap: () => context.push('/history'),
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
