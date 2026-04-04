import 'package:flutter/material.dart';
import '../../models/puzzle_config.dart';
import 'sudoku_cell.dart';
import 'board_overlay_painter.dart';

class SudokuBoard extends StatelessWidget {
  final PuzzleConfig config;

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
    required this.config,
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

  Border _cellBorder(int index, Color color) {
    final geo = config.geometry;
    final row = geo.rowOf(index);
    final col = geo.colOf(index);
    final thisBox = geo.boxOf(index);

    final topThick =
        row == 0 || geo.boxOf(geo.indexOf(row - 1, col)) != thisBox;
    final leftThick =
        col == 0 || geo.boxOf(geo.indexOf(row, col - 1)) != thisBox;
    final rightThick =
        col == geo.size - 1 || geo.boxOf(geo.indexOf(row, col + 1)) != thisBox;
    final bottomThick =
        row == geo.size - 1 || geo.boxOf(geo.indexOf(row + 1, col)) != thisBox;

    return Border(
      top:    BorderSide(width: topThick    ? 2.0 : 0.6, color: color),
      left:   BorderSide(width: leftThick   ? 2.0 : 0.6, color: color),
      right:  BorderSide(width: rightThick  ? 2.0 : 0.6, color: color),
      bottom: BorderSide(width: bottomThick ? 2.0 : 0.6, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final geo = config.geometry;

    final grid = GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: geo.size,
      ),
      itemCount: geo.cellCount,
      itemBuilder: (context, index) {
        final isGiven      = given[index] != 0;
        final isSelected   = selectedIndex == index;
        final isConflict   = conflicts.contains(index);
        final isPeer       = peerHighlights.contains(index);
        final isSameNumber = sameNumberHighlights.contains(index);

        final cellNotes = notes[index];
        final isNoteHighlighted =
            highlightNotesMask != 0 && (cellNotes & highlightNotesMask) != 0;

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
              border: _cellBorder(index, scheme.outline),
            ),
            child: SudokuCell(
              value: board[index],
              gridSize: geo.size,
              isGiven: isGiven,
              notesMask: cellNotes,
              isConflict: isConflict,
              isSelected: isSelected,
              highlightNotesMask: highlightNotesMask,
              isNoteHighlighted: isNoteHighlighted,
            ),
          ),
        );
      },
    );

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Background: thermo paths, diagonal/hyper tints
            Positioned.fill(
              child: CustomPaint(
                painter: BoardBackgroundPainter(config: config, scheme: scheme),
              ),
            ),
            // Cells (interactive)
            grid,
            // Foreground: killer cage outlines + sum labels
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BoardForegroundPainter(config: config, scheme: scheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
