# Sudoku Nova — Phase 0: Project Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the default counter app with a runnable Sudoku Nova scaffold — all dependencies, folder structure, neon theme, go_router config, and placeholder screens — so Phase 1 can build the engine into a working codebase.

**Architecture:** `main.dart` wraps the app in `ProviderScope` (Riverpod), then `App` widget provides `MaterialApp.router` wired to a `GoRouter` instance. Theme is centrally defined via `AppTheme`/`AppColors`. All five screens are stubs that render their name; full UI comes in later phases.

**Tech Stack:** Flutter + Dart 3.11, flutter_riverpod ^2.5.0, go_router ^14.0.0, google_fonts ^6.2.0, sqflite ^2.3.0, path ^1.9.0, shared_preferences ^2.2.0, intl ^0.19.0, flutter_animate ^4.5.0, audioplayers ^6.0.0.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Modify | `pubspec.yaml` | Add all dependencies |
| Modify | `lib/main.dart` | ProviderScope entry point |
| Create | `lib/app.dart` | MaterialApp.router + theme |
| Create | `lib/core/theme/app_colors.dart` | Color constants |
| Create | `lib/core/theme/app_theme.dart` | ThemeData + glow helpers |
| Create | `lib/core/constants/app_constants.dart` | Grid size, lives, hints |
| Create | `lib/core/router/app_router.dart` | GoRouter with 5 routes |
| Create | `lib/core/utils/duration_formatter.dart` | Seconds → MM:SS string |
| Create | `lib/core/utils/date_formatter.dart` | DateTime → display string |
| Create | `lib/features/menu/menu_screen.dart` | Placeholder menu |
| Create | `lib/features/difficulty/difficulty_screen.dart` | Placeholder difficulty |
| Create | `lib/features/game/game_screen.dart` | Placeholder game |
| Create | `lib/features/history/history_screen.dart` | Placeholder history |
| Create | `lib/features/result/result_screen.dart` | Placeholder result |
| Modify | `test/widget_test.dart` | Replace counter test with app smoke test |
| Create | `test/core/constants/app_constants_test.dart` | Unit tests for constants |
| Create | `test/core/utils/duration_formatter_test.dart` | Unit tests for formatter |
| Create | `test/core/utils/date_formatter_test.dart` | Unit tests for formatter |
| Create | `test/core/theme/app_theme_test.dart` | Unit tests for theme |

---

## Task 1: Add all dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Replace the `dependencies` block in pubspec.yaml**

The full replacement for the `dependencies:` section (keep `environment:`, `dev_dependencies:`, and `flutter:` sections unchanged):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  sqflite: ^2.3.0
  path: ^1.9.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  google_fonts: ^6.2.0
  flutter_animate: ^4.5.0
  audioplayers: ^6.0.0
```

- [ ] **Step 2: Fetch dependencies**

```bash
flutter pub get
```

Expected: Prints "Got dependencies." with no errors. A `pubspec.lock` with all packages is written.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add all project dependencies"
```

---

## Task 2: AppColors and AppConstants

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/constants/app_constants.dart`
- Create: `test/core/constants/app_constants_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/constants/app_constants_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('grid is 9x9 composed of 3x3 boxes', () {
      expect(AppConstants.gridSize, 9);
      expect(AppConstants.boxSize, 3);
      expect(AppConstants.boxSize * AppConstants.boxSize, AppConstants.gridSize);
    });

    test('max lives is 3', () {
      expect(AppConstants.maxLives, 3);
    });

    test('max hints is 2', () {
      expect(AppConstants.maxHints, 2);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/constants/app_constants_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/core/constants/app_constants.dart'`.

- [ ] **Step 3: Create app_colors.dart**

Create `lib/core/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141927);
  static const Color cyan = Color(0xFF00F5FF);
  static const Color green = Color(0xFF39FF14);
  static const Color purple = Color(0xFFBF00FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF6B7280);
  static const Color error = Color(0xFFFF4444);
}
```

- [ ] **Step 4: Create app_constants.dart**

Create `lib/core/constants/app_constants.dart`:

```dart
abstract final class AppConstants {
  static const int gridSize = 9;
  static const int boxSize = 3;
  static const int maxLives = 3;
  static const int maxHints = 2;
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/core/constants/app_constants_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_colors.dart lib/core/constants/app_constants.dart test/core/constants/app_constants_test.dart
git commit -m "feat: add AppColors and AppConstants"
```

---

## Task 3: DurationFormatter

**Files:**
- Create: `lib/core/utils/duration_formatter.dart`
- Create: `test/core/utils/duration_formatter_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/duration_formatter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    test('formats 0 seconds as 00:00', () {
      expect(DurationFormatter.format(0), '00:00');
    });

    test('formats 65 seconds as 01:05', () {
      expect(DurationFormatter.format(65), '01:05');
    });

    test('formats 3661 seconds as 61:01', () {
      expect(DurationFormatter.format(3661), '61:01');
    });

    test('pads single-digit seconds with leading zero', () {
      expect(DurationFormatter.format(9), '00:09');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/utils/duration_formatter_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/core/utils/duration_formatter.dart'`.

- [ ] **Step 3: Implement DurationFormatter**

Create `lib/core/utils/duration_formatter.dart`:

```dart
abstract final class DurationFormatter {
  static String format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/utils/duration_formatter_test.dart
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/duration_formatter.dart test/core/utils/duration_formatter_test.dart
git commit -m "feat: add DurationFormatter"
```

---

## Task 4: DateFormatter

**Files:**
- Create: `lib/core/utils/date_formatter.dart`
- Create: `test/core/utils/date_formatter_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/utils/date_formatter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final date = DateTime(2026, 6, 15);

    test('format returns long readable date', () {
      expect(DateFormatter.format(date), 'Jun 15, 2026');
    });

    test('formatShort returns compact MM/dd/yy date', () {
      expect(DateFormatter.formatShort(date), '06/15/26');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/utils/date_formatter_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/core/utils/date_formatter.dart'`.

- [ ] **Step 3: Implement DateFormatter**

Create `lib/core/utils/date_formatter.dart`:

```dart
import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static String format(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  static String formatShort(DateTime date) => DateFormat('MM/dd/yy').format(date);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/utils/date_formatter_test.dart
```

Expected: Both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/date_formatter.dart test/core/utils/date_formatter_test.dart
git commit -m "feat: add DateFormatter"
```

---

## Task 5: Placeholder Screens

**Files:**
- Create: `lib/features/menu/menu_screen.dart`
- Create: `lib/features/difficulty/difficulty_screen.dart`
- Create: `lib/features/game/game_screen.dart`
- Create: `lib/features/history/history_screen.dart`
- Create: `lib/features/result/result_screen.dart`
- Create: `test/features/menu/menu_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/menu/menu_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/features/menu/menu_screen.dart';

void main() {
  testWidgets('MenuScreen renders title text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Sudoku Nova'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/menu/menu_screen_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/features/menu/menu_screen.dart'`.

- [ ] **Step 3: Create all five placeholder screens**

Create `lib/features/menu/menu_screen.dart`:

```dart
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Sudoku Nova')),
    );
  }
}
```

Create `lib/features/difficulty/difficulty_screen.dart`:

```dart
import 'package:flutter/material.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Select Difficulty')),
    );
  }
}
```

Create `lib/features/game/game_screen.dart`:

```dart
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Game')),
    );
  }
}
```

Create `lib/features/history/history_screen.dart`:

```dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('History')),
    );
  }
}
```

Create `lib/features/result/result_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Result')),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/menu/menu_screen_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/ test/features/
git commit -m "feat: add placeholder screens for all five routes"
```

---

## Task 6: AppTheme

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/core/theme/app_theme.dart';
import 'package:sudoku/core/theme/app_colors.dart';

void main() {
  group('AppTheme', () {
    test('dark theme has dark brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('dark theme scaffold background is navy', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.background);
    });

    test('dark theme primary color is cyan', () {
      expect(AppTheme.dark.colorScheme.primary, AppColors.cyan);
    });

    test('glowDecoration returns BoxDecoration with a border and shadow', () {
      final decoration = AppTheme.glowDecoration();
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    test('glowDecoration cyan and purple shadows are different colors', () {
      final cyanDecoration = AppTheme.glowDecoration();
      final purpleDecoration = AppTheme.glowDecoration(color: AppColors.purple);
      expect(
        cyanDecoration.boxShadow!.first.color,
        isNot(purpleDecoration.boxShadow!.first.color),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/core/theme/app_theme.dart'`.

- [ ] **Step 3: Implement AppTheme**

Create `lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyan,
          secondary: AppColors.purple,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.orbitronTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      );

  static BoxDecoration glowDecoration({
    Color color = AppColors.cyan,
    double blurRadius = 12,
  }) =>
      BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: blurRadius,
            spreadRadius: 1,
          ),
        ],
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/theme/app_theme_test.dart
```

Expected: All 5 tests PASS.

> `google_fonts` downloads fonts at runtime. In an offline test environment it falls back silently — the tests still pass because they check theme properties, not rendered font appearance.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: add AppTheme with dark neon palette and glow helper"
```

---

## Task 7: AppRouter

**Files:**
- Create: `lib/core/router/app_router.dart`

GoRouter config is wired end-to-end in Task 8's integration test, so no isolated unit test here.

- [ ] **Step 1: Create app_router.dart**

Create `lib/core/router/app_router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../../features/difficulty/difficulty_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/result/result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/difficulty',
      builder: (context, state) => const DifficultyScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
  ],
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat: add go_router config with all five named routes"
```

---

## Task 8: App entry point — main.dart + app.dart

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/app.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Replace all contents of `test/widget_test.dart` with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/app.dart';

void main() {
  testWidgets('App launches and MenuScreen is visible', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    expect(find.text('Sudoku Nova'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget_test.dart
```

Expected: Compile error — `Target of URI doesn't exist: 'package:sudoku/app.dart'`.

- [ ] **Step 3: Create app.dart**

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sudoku Nova',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 4: Replace main.dart**

Replace all contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/widget_test.dart
```

Expected: PASS — app boots, GoRouter renders `MenuScreen`, "Sudoku Nova" text is found.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/app.dart test/widget_test.dart
git commit -m "feat: wire ProviderScope, MaterialApp.router, and AppTheme as entry point"
```

---

## Task 9: Full suite + static analysis

**Files:** None created — verify and fix.

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

Expected: All tests pass. Output ends with `All tests passed!`

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

If warnings appear, fix them before committing. Common issues:
- Unused imports → delete the import line
- `withOpacity` deprecation → already using `withValues(alpha:)` in AppTheme
- Missing `const` → add `const` where the analyzer suggests

- [ ] **Step 3: Commit if any fixes were made**

```bash
git add -p
git commit -m "fix: resolve static analysis warnings"
```

If no fixes were needed, skip this step.

- [ ] **Step 4: Verify the app runs on a connected Android device or emulator**

```bash
flutter run
```

Expected: App launches showing a dark navy screen with "Sudoku Nova" text centered. No red error screens.

---

## Phase 0 Complete

At this point the repo has:
- All dependencies resolved
- Full folder skeleton (`core/`, `data/`, `engine/`, `features/`, `shared/`)
- Neon dark theme wired to `MaterialApp.router`
- Five placeholder screens reachable via go_router
- 14 passing tests covering constants, formatters, theme, and app launch
- Clean `flutter analyze` output

Next: Phase 1 — build the pure-Dart Sudoku engine (solver, generator, validator) with full unit test coverage.
