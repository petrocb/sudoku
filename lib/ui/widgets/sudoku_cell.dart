import 'dart:math' show sqrt;
import 'package:flutter/material.dart';

class SudokuCell extends StatelessWidget {
  final int value;    // 0 = empty
  final int gridSize; // N (4, 6, 9, 12, 16 …)
  final bool isGiven;

  final int notesMask; // bitmask — bit n set means digit n is noted
  final bool isConflict;
  final bool isSelected;

  final int highlightNotesMask;
  final bool isNoteHighlighted;

  const SudokuCell({
    super.key,
    required this.value,
    required this.gridSize,
    required this.isGiven,
    required this.notesMask,
    required this.isConflict,
    required this.isSelected,
    required this.highlightNotesMask,
    required this.isNoteHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (value != 0) {
      final style = Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isGiven ? FontWeight.w800 : FontWeight.w600,
            color: isConflict ? scheme.onErrorContainer : scheme.onSurface,
          );
      return Center(child: Text('$value', style: style));
    }

    // ── Notes mini-grid ──────────────────────────────────────────────────────
    final isFiltering = highlightNotesMask != 0;
    final notesCols = sqrt(gridSize.toDouble()).ceil();

    final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isFiltering
              ? scheme.onSurfaceVariant.withValues(alpha: 0.2)
              : scheme.onSurfaceVariant,
        );

    final highlightedStyle = baseStyle?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w900,
      fontSize: (Theme.of(context).textTheme.labelSmall?.fontSize ?? 10) + 1,
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: notesCols,
        ),
        itemCount: gridSize,
        itemBuilder: (context, i) {
          final n = i + 1;
          final bit = 1 << n;
          if ((notesMask & bit) == 0) return const SizedBox.shrink();

          final shouldHighlight = isFiltering && (highlightNotesMask & bit) != 0;
          return Center(
            child: Text('$n', style: shouldHighlight ? highlightedStyle : baseStyle),
          );
        },
      ),
    );
  }
}
