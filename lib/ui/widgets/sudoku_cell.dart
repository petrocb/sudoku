import 'package:flutter/material.dart';

class SudokuCell extends StatelessWidget {
  final int value; // 0 = empty
  final bool isGiven;

  final int notesMask; // bitmask 1..9
  final bool isConflict;
  final bool isSelected;

  final int highlightNotesMask;
  final bool isNoteHighlighted;

  const SudokuCell({
    super.key,
    required this.value,
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

    // Notes mini-grid (1..9)
    final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        );

    final highlightedStyle = baseStyle?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: 9,
        itemBuilder: (context, i) {
          final n = i + 1;
          final bit = 1 << n;
          final has = (notesMask & bit) != 0;
          if (!has) return const SizedBox.shrink();

          final shouldHighlight = highlightNotesMask != 0 && (highlightNotesMask & bit) != 0;

          return Center(
            child: Text(
              '$n',
              style: shouldHighlight ? highlightedStyle : baseStyle,
            ),
          );
        },
      ),
    );
  }
}