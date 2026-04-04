import '../grid_geometry.dart';
import '../variant_constraint.dart';

/// Anti-King: no two king-adjacent cells (including diagonals) may share the same digit.
class AntiKingConstraint extends VariantConstraint {
  static const kType = 'anti_king';

  const AntiKingConstraint();

  @override
  String get type => kType;

  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) {
    final r = geo.rowOf(cellIndex);
    final c = geo.colOf(cellIndex);
    final peers = <int>{};
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < geo.size && nc >= 0 && nc < geo.size) {
          peers.add(geo.indexOf(nr, nc));
        }
      }
    }
    return peers;
  }

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) {
    final conflicts = <int>{};
    for (int i = 0; i < geo.cellCount; i++) {
      final v = board[i];
      if (v == 0) continue;
      for (final p in peersOf(i, geo)) {
        if (p > i && board[p] == v) {
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
    for (final p in peersOf(lastPlaced, geo)) {
      if (board[p] == v) return false;
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
    for (final p in peersOf(cellIndex, geo)) {
      final v = board[p];
      if (v != 0) used.add(v);
    }
    return candidates.difference(used);
  }

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static AntiKingConstraint fromJson(Map<String, dynamic> json) =>
      const AntiKingConstraint();
}
