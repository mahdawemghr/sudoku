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
    final colors = context.appColors;

    final canUndo = gameState.undoStack.isNotEmpty;
    final canHint = gameState.hintsLeft > 0;
    final notesActive = gameState.notesMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo ? () => controller.undo() : null,
            color: canUndo ? colors.primaryNeon : colors.textDisabled,
          ),
          _ActionButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onTap: () => controller.erase(),
            color: colors.primaryNeon,
          ),
          _ActionButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint (${gameState.hintsLeft})',
            onTap: canHint ? () => controller.hint() : null,
            color: canHint ? colors.accentPurple : colors.textDisabled,
          ),
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            onTap: () => controller.toggleNotesMode(),
            color:
                notesActive ? colors.secondaryNeon : colors.primaryNeon,
            isActive: notesActive,
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
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = context.appColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.18)
                    : surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      color.withValues(alpha: isActive ? 0.7 : 0.3),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
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
