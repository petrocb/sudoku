import 'grid_geometry.dart';

/// Abstract base for all Sudoku variant constraints.
///
/// Each constraint knows how to:
/// - identify peer cells (for note auto-clearing and UI highlighting)
/// - detect violations on the current board (for conflict highlighting)
/// - prune candidates during generation (for performance)
/// - serialize itself (for game save/load)
abstract class VariantConstraint {
  const VariantConstraint();

  String get type;

  /// All cells that share a uniqueness or relationship constraint with [cellIndex].
  /// Union of all constraints' peer sets = full peer set used by the game.
  Set<int> peersOf(int cellIndex, GridGeometry geo);

  /// Returns the set of cell indices that currently violate this constraint.
  Set<int> findViolations(List<int> board, GridGeometry geo);

  /// Fast check during backtracking: after placing a value at [lastPlaced],
  /// is the board still potentially solvable under this constraint?
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced);

  /// Removes values from [candidates] that this constraint forbids at [cellIndex]
  /// given the current partial [board]. Used during puzzle generation.
  Set<int> filterCandidates(
    Set<int> candidates,
    List<int> board,
    GridGeometry geo,
    int cellIndex,
  );

  Map<String, dynamic> toJson();
}
