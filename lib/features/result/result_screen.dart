import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';

class ResultScreen extends StatelessWidget {
  final bool won;
  final int duration;
  final String? difficulty;
  final bool isNewBest;

  const ResultScreen({
    super.key,
    required this.won,
    required this.duration,
    this.difficulty,
    required this.isNewBest,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accentColor = won ? colors.secondaryNeon : colors.errorRed;
    final headline = won ? 'Puzzle Solved!' : 'Game Over';
    final icon = won
        ? Icons.emoji_events_rounded
        : Icons.sentiment_dissatisfied_rounded;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 54),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
              ),
              const SizedBox(height: 28),

              Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              )
                  .animate(delay: 200.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 8),

              if (difficulty != null)
                Text(
                  difficulty!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),

              const SizedBox(height: 36),

              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 32),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Time',
                      value: DurationFormatter.format(duration),
                      valueColor: colors.primaryNeon,
                      labelColor: colors.textSecondary,
                    ),
                    if (won && isNewBest) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.secondaryNeon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.secondaryNeon.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.secondaryNeon.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded,
                                color: colors.secondaryNeon, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'New Best Time!',
                              style: TextStyle(
                                color: colors.secondaryNeon,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms),

              const SizedBox(height: 44),

              _ResultButton(
                label: 'PLAY AGAIN',
                color: accentColor,
                onTap: () => context.go(
                  '/game?difficulty=${difficulty ?? 'easy'}',
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 250.ms),
              const SizedBox(height: 14),

              _ResultButton(
                label: 'HOME',
                color: colors.textSecondary,
                onTap: () => context.go('/'),
              ).animate(delay: 600.ms).fadeIn(duration: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 15),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _ResultButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ResultButton> createState() => _ResultButtonState();
}

class _ResultButtonState extends State<_ResultButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: _pressed ? 0.9 : 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _pressed ? 0.25 : 0.12),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}
