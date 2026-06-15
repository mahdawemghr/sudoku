import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/action_buttons.dart';
import 'package:sudoku/features/game/widgets/game_hud.dart';
import 'package:sudoku/features/game/widgets/number_pad.dart';
import 'package:sudoku/features/game/widgets/sudoku_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String? difficulty;

  const GameScreen({super.key, this.difficulty});

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

    // Defer start to after the first frame so context is valid.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      controller.startNewGame(_difficulty);
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

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary),
          onPressed: () {
            ref.read(gameControllerProvider.notifier).pauseTimer();
            context.go('/');
          },
        ),
        title: Text(
          _difficulty.displayName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: gameState.isLoading
          ? const _LoadingView()
          : _GameView(phase: gameState.phase),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primaryNeon,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Generating puzzle…',
            style: TextStyle(
              color: AppColors.textSecondary,
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
    return SafeArea(
      child: Column(
        children: [
          const GameHud(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: const SudokuBoard(),
          ),
          const SizedBox(height: 16),
          const ActionButtons(),
          const SizedBox(height: 20),
          const NumberPad(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
