import '../grid_geometry.dart';
import '../variant_constraint.dart';

/// Thermo Sudoku: digits along each thermometer path must be strictly
/// increasing from the bulb (first element) to the tip (last element).
class ThermoConstraint extends VariantConstraint {
  static const kType = 'thermo';

  /// Each inner list is a thermo path ordered from bulb to tip.
  final List<List<int>> thermos;

  const ThermoConstraint({required this.thermos});

  @override
  String get type => kType;

  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) => {};

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) {
    final conflicts = <int>{};
    for (final thermo in thermos) {
      int prevVal = 0;
      for (final idx in thermo) {
        final v = board[idx];
        if (v == 0) {
          prevVal = 0; // gap — skip strict check
          continue;
        }
        if (prevVal != 0 && v <= prevVal) {
          conflicts.add(idx);
          // Also mark the predecessor
          final predIdx = thermo[thermo.indexOf(idx) - 1];
          conflicts.add(predIdx);
        }
        prevVal = v;
      }
    }
    return conflicts;
  }

  @override
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced) {
    for (final thermo in thermos) {
      final pos = thermo.indexOf(lastPlaced);
      if (pos == -1) continue;

      final v = board[lastPlaced];
      if (v == 0) continue;

      // Check predecessor
      if (pos > 0) {
        final prev = board[thermo[pos - 1]];
        if (prev != 0 && v <= prev) return false;
      }
      // Check successor
      if (pos < thermo.length - 1) {
        final next = board[thermo[pos + 1]];
        if (next != 0 && v >= next) return false;
      }
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
    for (final thermo in thermos) {
      final pos = thermo.indexOf(cellIndex);
      if (pos == -1) continue;

      int lowerBound = 0;  // value must be > lowerBound
      int upperBound = geo.size + 1; // value must be < upperBound

      // Find the nearest filled predecessor
      for (int i = pos - 1; i >= 0; i--) {
        final v = board[thermo[i]];
        if (v != 0) { lowerBound = v; break; }
      }
      // Find the nearest filled successor
      for (int i = pos + 1; i < thermo.length; i++) {
        final v = board[thermo[i]];
        if (v != 0) { upperBound = v; break; }
      }

      // Also constrain by position: must leave room for cells before/after
      // Minimum value = lowerBound + 1, but also ≥ pos + 1
      final minByPos = pos + 1;
      // Maximum value = upperBound - 1, but also ≤ size - (thermo.length - 1 - pos)
      final maxByPos = geo.size - (thermo.length - 1 - pos);

      final effectiveLow = lowerBound > minByPos - 1 ? lowerBound : minByPos - 1;
      final effectiveHigh = upperBound < maxByPos + 1 ? upperBound : maxByPos + 1;

      return candidates.where((v) => v > effectiveLow && v < effectiveHigh).toSet();
    }
    return candidates;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': kType,
        'thermos': thermos,
      };

  static ThermoConstraint fromJson(Map<String, dynamic> json) =>
      ThermoConstraint(
        thermos: (json['thermos'] as List)
            .map((t) => (t as List).map((e) => (e as num).toInt()).toList())
            .toList(),
      );
}
