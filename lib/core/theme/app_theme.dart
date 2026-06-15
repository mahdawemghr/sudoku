import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build(AppColorsExtension.dark, Brightness.dark);
  static ThemeData get lightTheme => _build(AppColorsExtension.light, Brightness.light);

  static ThemeData _build(AppColorsExtension c, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [c],

      colorScheme: isLight
          ? ColorScheme.light(
              primary: c.primaryNeon,
              secondary: c.secondaryNeon,
              tertiary: c.accentPurple,
              error: c.errorRed,
              surface: c.surface,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: c.textPrimary,
              onError: Colors.white,
              outline: c.border,
            )
          : ColorScheme.dark(
              primary: c.primaryNeon,
              secondary: c.secondaryNeon,
              tertiary: c.accentPurple,
              error: c.errorRed,
              surface: c.surface,
              onPrimary: c.background,
              onSecondary: c.background,
              onSurface: c.textPrimary,
              onError: c.textPrimary,
              outline: c.border,
            ),

      scaffoldBackgroundColor: c.background,

      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isLight ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
            color: c.textPrimary,
            fontSize: 57,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25),
        displayMedium: TextStyle(
            color: c.textPrimary,
            fontSize: 45,
            fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            color: c.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(
            color: c.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            color: c.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            color: c.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w500),
        titleLarge: TextStyle(
            color: c.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15),
        titleSmall: TextStyle(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1),
        bodyLarge: TextStyle(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5),
        bodyMedium: TextStyle(
            color: c.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25),
        bodySmall: TextStyle(
            color: c.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4),
        labelLarge: TextStyle(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.25),
        labelMedium: TextStyle(
            color: c.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0),
        labelSmall: TextStyle(
            color: c.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5),
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primaryNeon,
          foregroundColor: c.background,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaryNeon,
          side: BorderSide(color: c.primaryNeon, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textPrimary),
      ),

      dividerTheme:
          DividerThemeData(color: c.divider, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: TextStyle(color: c.textPrimary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        titleTextStyle: TextStyle(
            color: c.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600),
        contentTextStyle:
            TextStyle(color: c.textSecondary, fontSize: 14),
      ),
    );
  }
}
