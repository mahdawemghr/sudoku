import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textSecondary),
          onPressed: () {
            SoundService().playTap();
            context.go('/');
          },
        ),
        title: Text(
          'Select Difficulty',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _DifficultyButton(
                difficulty: Difficulty.easy,
                colorToken: _DifficultyColor.secondary,
                subtitle: 'Great for beginners',
                icon: Icons.sentiment_satisfied_alt_rounded,
              )
                  .animate(delay: 60.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),
              _DifficultyButton(
                difficulty: Difficulty.medium,
                colorToken: _DifficultyColor.primary,
                subtitle: 'A balanced challenge',
                icon: Icons.psychology_rounded,
              )
                  .animate(delay: 130.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),
              _DifficultyButton(
                difficulty: Difficulty.hard,
                colorToken: _DifficultyColor.accent,
                subtitle: 'Test your skills',
                icon: Icons.whatshot_rounded,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),
              _DifficultyButton(
                difficulty: Difficulty.impossible,
                colorToken: _DifficultyColor.error,
                subtitle: 'Only for masters',
                icon: Icons.dangerous_rounded,
              )
                  .animate(delay: 270.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DifficultyColor { primary, secondary, accent, error }

class _DifficultyButton extends StatefulWidget {
  final Difficulty difficulty;
  final _DifficultyColor colorToken;
  final String subtitle;
  final IconData icon;

  const _DifficultyButton({
    required this.difficulty,
    required this.colorToken,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<_DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<_DifficultyButton> {
  bool _pressed = false;

  Color _resolveColor(AppColorsExtension c) {
    switch (widget.colorToken) {
      case _DifficultyColor.primary:
        return c.primaryNeon;
      case _DifficultyColor.secondary:
        return c.secondaryNeon;
      case _DifficultyColor.accent:
        return c.accentPurple;
      case _DifficultyColor.error:
        return c.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _resolveColor(colors);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        SoundService().playTap();
        context.go('/game?difficulty=${widget.difficulty.label}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: 20.0, vertical: 18.0),
          decoration: BoxDecoration(
            color: _pressed
                ? color.withValues(alpha: 0.14)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: _pressed ? 0.9 : 0.5),
              width: _pressed ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _pressed ? 0.22 : 0.10),
                blurRadius: _pressed ? 18 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.difficulty.displayName,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
