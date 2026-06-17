import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/menu/widgets/best_score_card.dart';
import 'package:sudoku/shared/widgets/neon_button.dart';

final bestTimesProvider = FutureProvider.autoDispose<Map<Difficulty, int?>>((
  ref,
) async {
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
              const SizedBox(height: 56),

              // Title
              ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colors.primaryNeon, colors.accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'SUDOKU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: -0.25,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
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
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 44),

              NeonButton(
                    label: 'PLAY',
                    color: colors.primaryNeon,
                    onTap: () => context.push('/difficulty'),
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.25,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),

              savedGameAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (saved) {
                  if (saved == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    child:
                        NeonButton(
                              label:
                                  'RESUME  ${saved.difficulty.displayName.toUpperCase()}',
                              color: colors.secondaryNeon,
                              onTap: () => context.go('/game?resume=true'),
                            )
                            .animate(delay: 280.ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(
                              begin: 0.25,
                              end: 0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                  );
                },
              ),

              const SizedBox(height: 36),

              Row(
                children: [
                  Text(
                    'BEST SCORES',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: colors.border.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ).animate(delay: 340.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: 14),

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
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: Difficulty.values.indexed.map((entry) {
                    final (i, d) = entry;
                    return BestScoreCard(difficulty: d, bestTime: bestTimes[d])
                        .animate(delay: (380 + i * 60).ms)
                        .fadeIn(duration: 280.ms)
                        .scale(
                          begin: const Offset(0.88, 0.88),
                          end: const Offset(1, 1),
                          duration: 280.ms,
                          curve: Curves.easeOut,
                        );
                  }).toList(),
                ),
              ),

              const Spacer(),

              Row(
                    children: [
                      Expanded(
                        child: NeonButton(
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
                        semanticLabel: 'Settings',
                      ),
                    ],
                  )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconNeonButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String semanticLabel;

  const _IconNeonButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  State<_IconNeonButton> createState() => _IconNeonButtonState();
}

class _IconNeonButtonState extends State<_IconNeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          SoundService().playTap();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.91 : 1.0,
          duration: kButtonPressDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: kButtonPressDuration,
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _pressed ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.color.withValues(alpha: _pressed ? 0.9 : 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
        ),
      ),
    );
  }
}
