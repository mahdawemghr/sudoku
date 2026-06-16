import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/data/repositories/stats_repository.dart';
import 'package:sudoku/features/menu/widgets/best_score_card.dart';

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

              _NeonButton(
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
                        _NeonButton(
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

class _NeonButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 1.0 : 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.4 : 0.25),
                blurRadius: _pressed ? 20 : 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
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

  const _IconNeonButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_IconNeonButton> createState() => _IconNeonButtonState();
}

class _IconNeonButtonState extends State<_IconNeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
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
    );
  }
}
