import 'package:flutter/material.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/core/theme/app_colors.dart';

/// Shared press-feedback timing for neon-styled buttons (NeonButton here
/// and the icon-only button in the menu screen).
const Duration kButtonPressDuration = Duration(milliseconds: 80);

class NeonButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double verticalPadding;
  final double fontSize;
  final double letterSpacing;

  const NeonButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.verticalPadding = 18,
    this.fontSize = 18,
    this.letterSpacing = 3,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        SoundService().playTap();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: kButtonPressDuration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: kButtonPressDuration,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
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
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: widget.letterSpacing,
            ),
          ),
        ),
      ),
    );
  }
}

class NeonIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const NeonIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NeonSectionHeader extends StatelessWidget {
  final String label;

  const NeonSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Text(
          label,
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
    );
  }
}
