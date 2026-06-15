import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/action_buttons.dart';
import 'package:sudoku/features/game/widgets/game_hud.dart';
import 'package:sudoku/features/game/widgets/number_pad.dart';
import 'package:sudoku/features/game/widgets/sudoku_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String? difficulty;
  final bool resume;

  const GameScreen({super.key, this.difficulty, this.resume = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _difficulty = widget.difficulty != null
        ? DifficultyExtension.fromString(widget.difficulty!)
        : Difficulty.easy;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(gameControllerProvider.notifier);

      controller.onGameOver = (won, duration, isNewBest) {
        if (!mounted) return;
        context.go(
          '/result'
          '?won=$won'
          '&duration=$duration'
          '&difficulty=${_difficulty.label}'
          '&isNewBest=$isNewBest',
        );
      };

      if (widget.resume) {
        final saved = await GameRepository().loadCurrentGame();
        if (saved != null) {
          await controller.resumeGame(saved);
        } else {
          // Saved game disappeared — start fresh instead.
          await controller.startNewGame(_difficulty);
        }
      } else {
        await controller.startNewGame(_difficulty);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(gameControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      controller.resumeTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _exitToHome() {
    final controller = ref.read(gameControllerProvider.notifier);
    controller.pauseTimer();
    // Game is already saved on every move (and on startNewGame).
    // Just navigate — the saved state stays in SharedPreferences.
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitToHome();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: colors.textSecondary),
            onPressed: _exitToHome,
          ),
          title: Text(
            gameState.isLoading ? '' : gameState.difficulty.displayName,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: gameState.isLoading
            ? const _LoadingView()
            : _GameView(phase: gameState.phase),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: colors.primaryNeon,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Generating puzzle…',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  final GamePhase phase;

  const _GameView({required this.phase});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [
          GameHud(),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: SudokuBoard(),
          ),
          SizedBox(height: 16),
          ActionButtons(),
          SizedBox(height: 20),
          NumberPad(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
