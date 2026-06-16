import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sudoku/core/theme/app_colors.dart';

class SudokuCell extends StatefulWidget {
  final int value;
  final bool isGiven;
  final bool isSelected;
  final bool isMistake;
  final bool isCorrect;
  final bool isHighlighted;
  final bool isSameNumber;
  final Set<int> notes;
  final int? highlightedNote;
  final int? celebrationStep;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.value,
    required this.isGiven,
    required this.isSelected,
    required this.isMistake,
    required this.isCorrect,
    required this.isHighlighted,
    required this.isSameNumber,
    required this.notes,
    required this.onTap,
    this.highlightedNote,
    this.celebrationStep,
  });

  @override
  State<SudokuCell> createState() => _SudokuCellState();
}

class _SudokuCellState extends State<SudokuCell>
    with TickerProviderStateMixin {
  // Selection pulse
  late final AnimationController _selectCtrl;
  late final Animation<double> _selectScale;

  // Highlight entrance flash
  late final AnimationController _highlightCtrl;
  late final Animation<double> _highlightFlash;

  // Celebration bounce + glow
  late final AnimationController _celebCtrl;
  late final Animation<double> _celebScale;
  late final Animation<double> _celebGlow;

  @override
  void initState() {
    super.initState();

    _highlightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _highlightFlash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _highlightCtrl, curve: Curves.easeOut));

    _selectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _selectScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _selectCtrl, curve: Curves.easeOut));

    _celebCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _celebScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.92), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _celebCtrl, curve: Curves.easeOut));
    _celebGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 50),
    ]).animate(_celebCtrl);
  }

  @override
  void didUpdateWidget(SudokuCell old) {
    super.didUpdateWidget(old);

    // Highlight entrance flash
    if (!old.isHighlighted && widget.isHighlighted) {
      _highlightCtrl.forward(from: 0.0);
    }

    // Pulse on selection
    if (!old.isSelected && widget.isSelected) {
      _selectCtrl.forward(from: 0.0);
    }

    // Celebrate when a new step is assigned
    if (old.celebrationStep == null && widget.celebrationStep != null) {
      final delay = widget.celebrationStep! * 48;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _celebCtrl.forward(from: 0.0);
      });
    }
  }

  @override
  void dispose() {
    _highlightCtrl.dispose();
    _selectCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Alpha values scaled up in light mode — primaryNeon is dark teal (#0095A8) on white,
    // so 9% is invisible. Dark mode uses bright cyan (#00F5FF) where even 9% pops.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedAlpha   = isDark ? 0.22 : 0.42;
    final sameNumAlpha    = isDark ? 0.18 : 0.26;
    final highlightAlpha  = isDark ? 0.03 : 0.18;
    final mistakeAlpha    = isDark ? 0.20 : 0.18;

    // Background priority: mistake > selected > sameNumber > highlight > given > default
    final Color bg;
    if (widget.isMistake) {
      bg = colors.errorRed.withValues(alpha: mistakeAlpha);
    } else if (widget.isSelected) {
      bg = colors.primaryNeon.withValues(alpha: selectedAlpha);
    } else if (widget.isSameNumber) {
      bg = colors.primaryNeon.withValues(alpha: sameNumAlpha);
    } else if (widget.isHighlighted) {
      bg = colors.primaryNeon.withValues(alpha: highlightAlpha);
    } else if (widget.isGiven) {
      bg = colors.surfaceVariant;
    } else {
      bg = colors.surface;
    }

    final Color textColor;
    final FontWeight textWeight;
    final double textSize;
    if (widget.isMistake) {
      textColor = colors.errorRed;
      textWeight = FontWeight.w700;
      textSize = 18;
    } else if (widget.isGiven) {
      textColor = colors.textPrimary;
      textWeight = FontWeight.w800;
      textSize = 19;
    } else if (widget.isCorrect) {
      textColor = colors.secondaryNeon;
      textWeight = FontWeight.w600;
      textSize = 18;
    } else {
      textColor = colors.primaryNeon;
      textWeight = FontWeight.w500;
      textSize = 18;
    }

    final cellContent = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: widget.isSelected
              ? Border.all(color: colors.primaryNeon, width: 2.0)
              : null,
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryNeon
                        .withValues(alpha: isDark ? 0.45 : 0.35),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.value != 0
              ? Text(
                  '${widget.value}',
                  key: ValueKey(widget.value),
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                  ),
                )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 120.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 80.ms)
              : widget.notes.isNotEmpty
                  ? _NotesGrid(
                      notes: widget.notes,
                      colors: colors,
                      highlightedNote: widget.highlightedNote,
                      isDark: isDark,
                    )
                  : null,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_highlightCtrl, _selectCtrl, _celebCtrl]),
      builder: (context, child) {
        final scale = _selectScale.value *
            (_celebCtrl.isAnimating ? _celebScale.value : 1.0);
        final celebGlow = _celebGlow.value;
        final hlFlash = _highlightFlash.value;

        return Transform.scale(
          scale: scale,
          child: Stack(
            children: [
              child!,
              // Highlight entrance flash (primaryNeon, subtle)
              if (hlFlash > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primaryNeon.withValues(alpha: hlFlash * 0.28),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primaryNeon
                                .withValues(alpha: hlFlash * 0.40),
                            blurRadius: 10 * hlFlash,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Celebration glow overlay (secondaryNeon, stronger)
              if (celebGlow > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.secondaryNeon
                            .withValues(alpha: celebGlow * 0.38),
                        boxShadow: [
                          BoxShadow(
                            color: colors.secondaryNeon
                                .withValues(alpha: celebGlow * 0.55),
                            blurRadius: 12 * celebGlow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: cellContent,
    );
  }
}

/// 3×3 candidate notes rendered without GridView — lighter and reliable in small cells.
class _NotesGrid extends StatelessWidget {
  final Set<int> notes;
  final AppColorsExtension colors;
  final int? highlightedNote;
  final bool isDark;

  const _NotesGrid({
    required this.notes,
    required this.colors,
    required this.isDark,
    this.highlightedNote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale notes to the cell's actual rendered size (measured inside
          // the padding above) instead of a fixed pixel guess, so they stay
          // legible across phone/tablet screen sizes without overflowing.
          final slotWidth = constraints.maxWidth / 3;
          final fontSize = (slotWidth * 0.68).clamp(8.0, 18.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _noteRow([1, 2, 3], slotWidth, fontSize),
              _noteRow([4, 5, 6], slotWidth, fontSize),
              _noteRow([7, 8, 9], slotWidth, fontSize),
            ],
          );
        },
      ),
    );
  }

  Widget _noteRow(List<int> nums, double slotWidth, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: nums.map((n) {
        if (!notes.contains(n)) return SizedBox(width: slotWidth);
        final isHighlighted = n == highlightedNote;
        return SizedBox(
          width: slotWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$n',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHighlighted
                    ? colors.primaryNeon
                    : (isDark ? colors.textPrimary : colors.accentPurple),
                fontSize: isHighlighted ? fontSize * 1.15 : fontSize,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
