import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sudoku/core/services/sound_service.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/data/models/difficulty.dart';
import 'package:sudoku/data/models/saved_game.dart';
import 'package:sudoku/data/repositories/game_repository.dart';
import 'package:sudoku/engine/hint_explainer.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';
import 'package:sudoku/features/game/state/game_state.dart';
import 'package:sudoku/features/game/widgets/action_buttons.dart';
import 'package:sudoku/features/game/widgets/game_hud.dart';
import 'package:sudoku/features/game/widgets/hint_banner.dart';
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
  HintExplanation? _activeHint;
  Timer? _hintTimer;

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
        void navigate() {
          if (!mounted) return;
          context.go(
            '/result'
            '?won=$won'
            '&duration=$duration'
            '&difficulty=${_difficulty.label}'
            '&isNewBest=$isNewBest',
          );
        }

        if (!mounted) return;
        if (won) {
          Future.delayed(kWinCelebrationDelay, navigate);
        } else {
          navigate();
        }
      };

      controller.onHint = (explanation) {
        if (!mounted) return;
        setState(() => _activeHint = explanation);
        _hintTimer?.cancel();
        _hintTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) _dismissHint();
        });
      };

      if (widget.resume) {
        SavedGame? saved;
        try {
          saved = await GameRepository().loadCurrentGame();
        } catch (e) {
          // Corrupted or schema-incompatible save data — fall back to a new
          // game instead of leaving the screen stuck on the loading spinner.
          debugPrint('[GameScreen] loadCurrentGame failed, starting a new game: $e');
        }
        if (saved != null) {
          await controller.resumeGame(saved);
        } else {
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
    _hintTimer?.cancel();
    super.dispose();
  }

  void _exitToHome() {
    SoundService().playTap();
    final controller = ref.read(gameControllerProvider.notifier);
    controller.pauseTimer();
    context.go('/');
  }

  void _dismissHint() {
    if (_activeHint == null) return;
    _hintTimer?.cancel();
    SoundService().playDismiss();
    setState(() => _activeHint = null);
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
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: gameState.isLoading
                ? const SizedBox.shrink()
                : Text(
                    gameState.difficulty.displayName,
                    key: const ValueKey('title'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          centerTitle: true,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: gameState.isLoading
              ? const _LoadingView(key: ValueKey('loading'))
              : _GameView(
                  key: const ValueKey('game'),
                  phase: gameState.phase,
                  hint: _activeHint,
                  onDismissHint: _dismissHint,
                ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

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
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 1200.ms, curve: Curves.linear),
          const SizedBox(height: 20),
          Text(
            'Generating puzzle…',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }
}

class _GameView extends StatelessWidget {
  final GamePhase phase;
  final HintExplanation? hint;
  final VoidCallback onDismissHint;

  const _GameView({
    super.key,
    required this.phase,
    required this.hint,
    required this.onDismissHint,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const GameHud()
              .animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .slideY(begin: -0.15, end: 0, duration: 300.ms, curve: Curves.easeOut),
          const SizedBox(height: 6),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: hint == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: HintBanner(
                      key: ValueKey(hint),
                      explanation: hint!,
                      onDismiss: onDismissHint,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: const SudokuBoard()
                .animate(delay: 80.ms)
                .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  duration: 350.ms,
                  curve: Curves.easeOut,
                ),
          ),
          const SizedBox(height: 14),
          const ActionButtons()
              .animate(delay: 160.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOut),
          const SizedBox(height: 18),
          const NumberPad()
              .animate(delay: 220.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
