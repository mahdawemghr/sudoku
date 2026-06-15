import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';

class ActionButtons extends ConsumerWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final gameState = ref.watch(gameControllerProvider);

    final canUndo = gameState.undoStack.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo ? () => controller.undo() : null,
            color: canUndo
                ? AppColors.primaryNeon
                : AppColors.textDisabled,
          ),
          _ActionButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onTap: () => controller.erase(),
            color: AppColors.primaryNeon,
          ),
          _ActionButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            onTap: null, // Stub for Phase 5
            color: AppColors.textDisabled,
          ),
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            onTap: null, // Stub for Phase 5
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
