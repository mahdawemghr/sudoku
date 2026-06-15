import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Select Difficulty',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _DifficultyButton(
                difficulty: Difficulty.easy,
                color: AppColors.secondaryNeon,
                subtitle: 'Great for beginners',
                icon: Icons.sentiment_satisfied_alt_rounded,
              ),
              const SizedBox(height: 16),
              _DifficultyButton(
                difficulty: Difficulty.medium,
                color: AppColors.primaryNeon,
                subtitle: 'A balanced challenge',
                icon: Icons.psychology_rounded,
              ),
              const SizedBox(height: 16),
              _DifficultyButton(
                difficulty: Difficulty.hard,
                color: AppColors.accentPurple,
                subtitle: 'Test your skills',
                icon: Icons.whatshot_rounded,
              ),
              const SizedBox(height: 16),
              _DifficultyButton(
                difficulty: Difficulty.impossible,
                color: AppColors.errorRed,
                subtitle: 'Only for masters',
                icon: Icons.dangerous_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final Difficulty difficulty;
  final Color color;
  final String subtitle;
  final IconData icon;

  const _DifficultyButton({
    required this.difficulty,
    required this.color,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/game?difficulty=${difficulty.label}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
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
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.displayName,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
