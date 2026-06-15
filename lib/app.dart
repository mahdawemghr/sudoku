import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/sound_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_screen.dart';

class SudokuNovaApp extends ConsumerWidget {
  const SudokuNovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<bool>(soundEnabledProvider, (prev, next) {
      SoundService().setSoundEnabled(next);
    });

    return MaterialApp.router(
      title: 'Sudoku Nova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
