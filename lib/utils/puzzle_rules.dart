import '../models/grid_geometry.dart';
import '../models/puzzle_config.dart';

/// Runtime rule engine for a specific [PuzzleConfig].
///
/// Aggregates peer sets and violation detection across all active constraints.
/// Peer sets are cached per cell index since they depend only on the config,
/// not on the board state.
class PuzzleRules {
  final PuzzleConfig config;
  GridGeometry get _geo => config.geometry;

  PuzzleRules(this.config);

  final Map<int, Set<int>> _peerCache = {};

  /// Union of all constraint peer sets for [cellIndex].
  /// Used for: note auto-clearing, peer cell highlighting.
  Set<int> peersOf(int cellIndex) {
    return _peerCache.putIfAbsent(cellIndex, () {
      final result = <int>{};
      for (final c in config.constraints) {
        result.addAll(c.peersOf(cellIndex, _geo));
      }
      result.remove(cellIndex);
      return result;
    });
  }

  /// Union of all constraint violations across the full [board].
  Set<int> findConflicts(List<int> board) {
    final result = <int>{};
    for (final c in config.constraints) {
      result.addAll(c.findViolations(board, _geo));
    }
    return result;
  }

  /// All cells that contain [value] (for same-number highlighting).
  Set<int> sameValueCells(List<int> board, int value) {
    final out = <int>{};
    for (int i = 0; i < _geo.cellCount; i++) {
      if (board[i] == value) out.add(i);
    }
    return out;
  }

  /// True if the board is completely and correctly filled.
  bool isSolved(List<int> board) {
    if (board.length != _geo.cellCount) return false;
    if (board.any((v) => v == 0)) return false;
    return findConflicts(board).isEmpty;
  }

  /// Filters [candidates] through all constraints for [cellIndex].
  /// Used during puzzle generation to prune the search space.
  Set<int> filterCandidates(Set<int> candidates, List<int> board, int cellIndex) {
    var result = candidates;
    for (final c in config.constraints) {
      result = c.filterCandidates(result, board, _geo, cellIndex);
      if (result.isEmpty) return result;
    }
    return result;
  }
}
