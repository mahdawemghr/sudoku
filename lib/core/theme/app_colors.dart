import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primaryNeon,
    required this.secondaryNeon,
    required this.accentPurple,
    required this.errorRed,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.overlayDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primaryNeon;
  final Color secondaryNeon;
  final Color accentPurple;
  final Color errorRed;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color divider;
  final Color overlayDark;

  static const AppColorsExtension dark = AppColorsExtension(
    background: Color(0xFF0D1117),
    surface: Color(0xFF1A2332),
    surfaceVariant: Color(0xFF243040),
    primaryNeon: Color(0xFF00F5FF),
    secondaryNeon: Color(0xFF39FF14),
    accentPurple: Color(0xFFBF5FFF),
    errorRed: Color(0xFFFF4444),
    textPrimary: Color(0xFFE8F4F8),
    textSecondary: Color(0xFF8BA3B0),
    textDisabled: Color(0xFF4A5568),
    border: Color(0xFF2D3F54),
    divider: Color(0xFF1E2D3D),
    overlayDark: Color(0x80000000),
  );

  static const AppColorsExtension light = AppColorsExtension(
    background: Color(0xFFF0F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE4ECF4),
    primaryNeon: Color(0xFF0095A8),
    secondaryNeon: Color(0xFF1A8C00),
    accentPurple: Color(0xFF7C3AED),
    errorRed: Color(0xFFDC2626),
    textPrimary: Color(0xFF0D1117),
    textSecondary: Color(0xFF4B6280),
    textDisabled: Color(0xFF9CA3AF),
    border: Color(0xFFCDD7E3),
    divider: Color(0xFFE5EBF2),
    overlayDark: Color(0x80000000),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? primaryNeon,
    Color? secondaryNeon,
    Color? accentPurple,
    Color? errorRed,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? divider,
    Color? overlayDark,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      primaryNeon: primaryNeon ?? this.primaryNeon,
      secondaryNeon: secondaryNeon ?? this.secondaryNeon,
      accentPurple: accentPurple ?? this.accentPurple,
      errorRed: errorRed ?? this.errorRed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      overlayDark: overlayDark ?? this.overlayDark,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      primaryNeon: Color.lerp(primaryNeon, other.primaryNeon, t)!,
      secondaryNeon: Color.lerp(secondaryNeon, other.secondaryNeon, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      errorRed: Color.lerp(errorRed, other.errorRed, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      overlayDark: Color.lerp(overlayDark, other.overlayDark, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
