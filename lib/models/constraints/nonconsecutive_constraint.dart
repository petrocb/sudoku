import '../grid_geometry.dart';
import '../variant_constraint.dart';

/// Nonconsecutive: no two orthogonally adjacent cells may contain digits that
/// differ by exactly 1 (e.g., 3 and 4 cannot be neighbours).
class NonconsecutiveConstraint extends VariantConstraint {
  static const kType = 'nonconsecutive';

  const NonconsecutiveConstraint();

  @override
  String get type => kType;

  /// Returns orthogonal neighbours — used for UI peer highlighting only.
  /// Note: this is NOT a standard uniqueness peer set; the constraint is about
  /// consecutive values, not identical values.
  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) {
    return _orthogonalNeighbours(cellIndex, geo);
  }

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) {
    final conflicts = <int>{};
    for (int i = 0; i < geo.cellCount; i++) {
      final v = board[i];
      if (v == 0) continue;
      for (final p in _orthogonalNeighbours(i, geo)) {
        final nv = board[p];
        if (nv != 0 && (nv - v).abs() == 1) {
          conflicts.add(i);
          conflicts.add(p);
        }
      }
    }
    return conflicts;
  }

  @override
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced) {
    final v = board[lastPlaced];
    if (v == 0) return true;
    for (final p in _orthogonalNeighbours(lastPlaced, geo)) {
      final nv = board[p];
      if (nv != 0 && (nv - v).abs() == 1) return false;
    }
    return true;
  }

  @override
  Set<int> filterCandidates(
    Set<int> candidates,
    List<int> board,
    GridGeometry geo,
    int cellIndex,
  ) {
    final forbidden = <int>{};
    for (final p in _orthogonalNeighbours(cellIndex, geo)) {
      final nv = board[p];
      if (nv != 0) {
        if (nv > 1) forbidden.add(nv - 1);
        if (nv < geo.size) forbidden.add(nv + 1);
      }
    }
    return candidates.difference(forbidden);
  }

  Set<int> _orthogonalNeighbours(int idx, GridGeometry geo) {
    final r = geo.rowOf(idx);
    final c = geo.colOf(idx);
    final result = <int>{};
    if (r > 0) result.add(geo.indexOf(r - 1, c));
    if (r < geo.size - 1) result.add(geo.indexOf(r + 1, c));
    if (c > 0) result.add(geo.indexOf(r, c - 1));
    if (c < geo.size - 1) result.add(geo.indexOf(r, c + 1));
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static NonconsecutiveConstraint fromJson(Map<String, dynamic> json) =>
      const NonconsecutiveConstraint();
}
