import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku/core/theme/app_colors.dart';
import 'package:sudoku/features/game/controller/game_controller.dart';

class NumberPad extends ConsumerWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final grid = ref.watch(gameControllerProvider).currentGrid;

    // Count how many times each digit appears in the solved grid.
    final counts = List.filled(10, 0);
    for (final row in grid) {
      for (final v in row) {
        if (v > 0) counts[v]++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          final number = index + 1;
          final complete = counts[number] >= 9;
          return _NumberButton(
            number: number,
            complete: complete,
            onTap: complete ? null : () => controller.enterNumber(number),
          );
        }),
      ),
    );
  }
}

class _NumberButton extends StatefulWidget {
  final int number;
  final bool complete;
  final VoidCallback? onTap;

  const _NumberButton({
    required this.number,
    required this.complete,
    required this.onTap,
  });

  @override
  State<_NumberButton> createState() => _NumberButtonState();
}

class _NumberButtonState extends State<_NumberButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = !widget.complete;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.87 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 34,
          height: 50,
          decoration: BoxDecoration(
            color: widget.complete
                ? colors.secondaryNeon.withValues(alpha: 0.12)
                : _pressed
                    ? colors.primaryNeon.withValues(alpha: 0.15)
                    : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.complete
                  ? colors.secondaryNeon.withValues(alpha: 0.55)
                  : colors.primaryNeon
                      .withValues(alpha: _pressed ? 0.85 : 0.40),
              width: widget.complete ? 1.5 : (_pressed ? 1.5 : 1.0),
            ),
            boxShadow: widget.complete
                ? [
                    BoxShadow(
                      color: colors.secondaryNeon.withValues(alpha: 0.18),
                      blurRadius: 8,
                    ),
                  ]
                : _pressed
                    ? null
                    : [
                        BoxShadow(
                          color: colors.primaryNeon.withValues(alpha: 0.10),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: widget.complete
                  ? Icon(
                      Icons.check_rounded,
                      key: const ValueKey('check'),
                      color: colors.secondaryNeon,
                      size: 20,
                    )
                  : Text(
                      '${widget.number}',
                      key: ValueKey(widget.number),
                      style: TextStyle(
                        color: _pressed
                            ? colors.primaryNeon
                            : colors.primaryNeon.withValues(alpha: 0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
