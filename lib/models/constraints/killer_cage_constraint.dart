import '../grid_geometry.dart';
import '../variant_constraint.dart';

class CageData {
  final List<int> cells;
  final int targetSum;

  const CageData({required this.cells, required this.targetSum});

  Map<String, dynamic> toJson() => {
        'cells': cells,
        'sum': targetSum,
      };

  static CageData fromJson(Map<String, dynamic> json) => CageData(
        cells: (json['cells'] as List).map((e) => (e as num).toInt()).toList(),
        targetSum: (json['sum'] as num).toInt(),
      );
}

/// Killer Sudoku: the board is partitioned into cages.
/// Each cage's cells must sum to [targetSum] and contain no repeated digits.
class KillerCageConstraint extends VariantConstraint {
  static const kType = 'killer_cages';

  final List<CageData> cages;

  const KillerCageConstraint({required this.cages});

  @override
  String get type => kType;

  /// All other cells in the same cage as [cellIndex].
  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) {
    for (final cage in cages) {
      if (cage.cells.contains(cellIndex)) {
        return cage.cells.where((c) => c != cellIndex).toSet();
      }
    }
    return {};
  }

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) {
    final conflicts = <int>{};
    for (final cage in cages) {
      final vals = cage.cells.map((c) => board[c]).where((v) => v != 0).toList();
      // No repeats
      final seen = <int>{};
      for (int i = 0; i < cage.cells.length; i++) {
        final v = board[cage.cells[i]];
        if (v == 0) continue;
        if (!seen.add(v)) conflicts.add(cage.cells[i]);
      }
      // Sum check when all cells filled
      if (vals.length == cage.cells.length) {
        final sum = vals.reduce((a, b) => a + b);
        if (sum != cage.targetSum) conflicts.addAll(cage.cells);
      }
    }
    return conflicts;
  }

  @override
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced) {
    for (final cage in cages) {
      if (!cage.cells.contains(lastPlaced)) continue;

      final filledVals = cage.cells.map((c) => board[c]).where((v) => v != 0).toList();
      final partialSum = filledVals.reduce((a, b) => a + b);

      // Partial sum must not exceed target
      if (partialSum > cage.targetSum) return false;

      // No repeats
      if (filledVals.toSet().length != filledVals.length) return false;

      // If all filled, sum must match exactly
      if (filledVals.length == cage.cells.length && partialSum != cage.targetSum) {
        return false;
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
    for (final cage in cages) {
      if (!cage.cells.contains(cellIndex)) continue;

      final filledVals = cage.cells
          .where((c) => c != cellIndex && board[c] != 0)
          .map((c) => board[c])
          .toSet();

      final partialSum = filledVals.isEmpty
          ? 0
          : filledVals.reduce((a, b) => a + b);

      final remaining = cage.cells.where((c) => c != cellIndex && board[c] == 0).length;

      return candidates.where((v) {
        if (filledVals.contains(v)) return false; // no repeat
        final newPartial = partialSum + v;
        if (newPartial > cage.targetSum) return false;
        // Minimum achievable sum with remaining empty cells
        if (newPartial + remaining < cage.targetSum) return false;
        return true;
      }).toSet();
    }
    return candidates;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': kType,
        'cages': cages.map((c) => c.toJson()).toList(),
      };

  static KillerCageConstraint fromJson(Map<String, dynamic> json) =>
      KillerCageConstraint(
        cages: (json['cages'] as List)
            .map((c) => CageData.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}
