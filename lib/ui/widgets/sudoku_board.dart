import 'package:flutter/material.dart';
import 'sudoku_cell.dart';

class SudokuBoard extends StatelessWidget {
  final List<int> given;
  final List<int> board;
  final List<int> notes;

  final int? selectedIndex;
  final Set<int> conflicts;
  final Set<int> peerHighlights;
  final Set<int> sameNumberHighlights;
  final int highlightNotesMask;

  final void Function(int index) onTapCell;

  const SudokuBoard({
    super.key,
    required this.given,
    required this.board,
    required this.notes,
    required this.selectedIndex,
    required this.conflicts,
    required this.peerHighlights,
    required this.sameNumberHighlights,
    required this.highlightNotesMask,
    required this.onTapCell,
  });

  int _rowOf(int i) => i ~/ 9;
  int _colOf(int i) => i % 9;

  Border _cellBorder(int row, int col, Color color) {
    final top = row % 3 == 0 ? 2.0 : 0.6;
    final left = col % 3 == 0 ? 2.0 : 0.6;
    final right = (col == 8) ? 2.0 : 0.6;
    final bottom = (row == 8) ? 2.0 : 0.6;

    return Border(
      top: BorderSide(width: top, color: color),
      left: BorderSide(width: left, color: color),
      right: BorderSide(width: right, color: color),
      bottom: BorderSide(width: bottom, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = _rowOf(index);
            final col = _colOf(index);

            final isGiven = given[index] != 0;
            final isSelected = selectedIndex == index;
            final isConflict = conflicts.contains(index);
            final isPeer = peerHighlights.contains(index);
            final isSameNumber = sameNumberHighlights.contains(index);

            // Notes highlight: if this cell has notes and it contains the selected number note bit
            final cellNotesMask = notes[index];
            final isNoteHighlighted = highlightNotesMask != 0 && (cellNotesMask & highlightNotesMask) != 0;

            final bg = isConflict
                ? scheme.errorContainer
                : isSelected
                    ? scheme.secondaryContainer
                    : isSameNumber
                        ? scheme.tertiaryContainer
                        : isPeer
                            ? scheme.surfaceContainerHighest
                            : isGiven
                                ? scheme.surfaceContainerHigh
                                : scheme.surface;

            return InkWell(
              onTap: () => onTapCell(index),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: _cellBorder(row, col, scheme.outline),
                ),
                child: SudokuCell(
                  value: board[index],
                  isGiven: isGiven,
                  notesMask: notes[index],
                  isConflict: isConflict,
                  isSelected: isSelected,
                  highlightNotesMask: highlightNotesMask,
                  isNoteHighlighted: isNoteHighlighted,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}