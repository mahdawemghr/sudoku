import 'package:flutter/material.dart';
import 'package:sudoku/core/theme/app_colors.dart';

/// A container with a neon glow box-shadow effect.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double glowRadius;
  final double spreadRadius;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.glowRadius = 16,
    this.spreadRadius = 0,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedGlow = glowColor ?? colors.primaryNeon;
    final resolvedBg = backgroundColor ?? colors.surface;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border,
        boxShadow: [
          BoxShadow(
            color: resolvedGlow.withValues(alpha: 0.30),
            blurRadius: glowRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Circle icon container with neon glow — used on result screen and elsewhere.
class GlowCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const GlowCircle({
    super.key,
    required this.icon,
    required this.color,
    this.size = 96,
    this.iconSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
