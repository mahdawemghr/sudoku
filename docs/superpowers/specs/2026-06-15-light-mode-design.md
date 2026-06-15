# Light Mode Design — Sudoku Nova

## Summary
Add system-following light/dark theme support using Flutter's `ThemeExtension` pattern. The app automatically matches the device's system brightness — no manual toggle needed.

## Architecture

### AppColorsExtension (ThemeExtension)
Replace the static `AppColors` class with `AppColorsExtension extends ThemeExtension<AppColorsExtension>`. It carries the full color palette as instance fields and provides two static constants: `AppColorsExtension.dark` (current colours) and `AppColorsExtension.light` (new palette). Registered in both `ThemeData` objects via the `extensions` field.

A `BuildContext` extension (`context.appColors`) gives widgets a one-line accessor.

### Light Palette
| Token | Value | Note |
|---|---|---|
| background | `#F0F4F8` | light blue-gray |
| surface | `#FFFFFF` | white cards |
| surfaceVariant | `#E4ECF4` | tinted rows/boxes |
| primaryNeon | `#0095A8` | teal — readable cyan on white |
| secondaryNeon | `#1A8C00` | forest green |
| accentPurple | `#7C3AED` | rich purple |
| errorRed | `#DC2626` | clear red |
| textPrimary | `#0D1117` | near-black |
| textSecondary | `#4B6280` | mid blue-gray |
| textDisabled | `#9CA3AF` | light gray |
| border | `#CDD7E3` | light border |
| divider | `#E5EBF2` | very light |

### AppTheme
- `lightTheme` added alongside existing `darkTheme`; both register their respective `AppColorsExtension` constant.
- `app.dart` sets `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: ThemeMode.system`.

### Widget Updates
Every widget that currently reads `AppColors.X` is updated to `context.appColors.X`. `_BoardGridPainter` (CustomPainter, no context) receives colors as a constructor parameter.

## Files Changed
- `lib/core/theme/app_colors.dart` — replace static class with ThemeExtension + context extension
- `lib/core/theme/app_theme.dart` — add lightTheme
- `lib/app.dart` — ThemeMode.system
- ~15 widget/screen files — AppColors.X → context.appColors.X
