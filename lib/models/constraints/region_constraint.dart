import '../grid_geometry.dart';
import '../variant_constraint.dart';

/// Abstract base for constraints that add extra uniqueness regions.
/// Subclasses only need to implement [regions] and serialization.
abstract class RegionConstraint extends VariantConstraint {
  const RegionConstraint();

  /// The list of cell-index groups that must each contain unique values.
  List<List<int>> regions(GridGeometry geo);

  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) {
    final peers = <int>{};
    for (final region in regions(geo)) {
      if (region.contains(cellIndex)) peers.addAll(region);
    }
    peers.remove(cellIndex);
    return peers;
  }

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) {
    final conflicts = <int>{};
    for (final region in regions(geo)) {
      final seen = <int, int>{};
      for (final idx in region) {
        final v = board[idx];
        if (v == 0) continue;
        if (seen.containsKey(v)) {
          conflicts.add(seen[v]!);
          conflicts.add(idx);
        } else {
          seen[v] = idx;
        }
      }
    }
    return conflicts;
  }

  @override
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced) {
    final v = board[lastPlaced];
    if (v == 0) return true;
    for (final peer in peersOf(lastPlaced, geo)) {
      if (board[peer] == v) return false;
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
    final used = <int>{};
    for (final peer in peersOf(cellIndex, geo)) {
      final v = board[peer];
      if (v != 0) used.add(v);
    }
    return candidates.difference(used);
  }
}
