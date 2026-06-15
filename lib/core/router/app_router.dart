import 'package:go_router/go_router.dart';

import '../../features/difficulty/difficulty_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String menu = '/';
  static const String difficulty = '/difficulty';
  static const String game = '/game';
  static const String history = '/history';
  static const String result = '/result';
  static const String settings = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.menu,
  routes: [
    GoRoute(
      path: AppRoutes.menu,
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: AppRoutes.difficulty,
      builder: (context, state) => const DifficultyScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) {
        final difficulty = state.uri.queryParameters['difficulty'];
        final resume = state.uri.queryParameters['resume'] == 'true';
        return GameScreen(difficulty: difficulty, resume: resume);
      },
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.result,
      builder: (context, state) {
        final params = state.uri.queryParameters;
        final won = params['won'] == 'true';
        final duration = int.tryParse(params['duration'] ?? '0') ?? 0;
        final difficulty = params['difficulty'];
        final isNewBest = params['isNewBest'] == 'true';
        return ResultScreen(
          won: won,
          duration: duration,
          difficulty: difficulty,
          isNewBest: isNewBest,
        );
      },
    ),
  ],
);
