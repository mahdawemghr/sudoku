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
            icon: Icons.lightbulb_rounded,
            label: 'Hint (${gameState.hintsLeft})',
            onTap: canHint ? () => controller.hint() : null,
            color: canHint ? colors.accentPurple : colors.textDisabled,
          ),
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Notes',
            onTap: () => controller.toggleNotesMode(),
            color: notesActive ? colors.secondaryNeon : colors.primaryNeon,
            isActive: notesActive,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? widget.color.withValues(alpha: 0.20)
                      : _pressed
                          ? widget.color.withValues(alpha: 0.14)
                          : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: widget.color.withValues(
                      alpha: widget.isActive
                          ? 0.85
                          : _pressed
                              ? 0.80
                              : 0.40,
                    ),
                    width: widget.isActive || _pressed ? 1.5 : 1.0,
                  ),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.30),
                            blurRadius: 12,
                          ),
                        ]
                      : _pressed
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.18),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight:
                    widget.isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
