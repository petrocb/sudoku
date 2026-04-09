import 'dart:math';

import '../models/grid_geometry.dart';
import '../models/constraints/killer_cage_constraint.dart';
import '../models/constraints/thermo_constraint.dart';

/// Generates constraint overlay data (cages, thermos, jigsaw regions)
/// from a completed solution board.
class ConstraintGenerator {
  final Random _rng;

  ConstraintGenerator({int? seed})
      : _rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);

  // ── Jigsaw regions ──────────────────────────────────────────────────────────

  /// Generates [geo.size] connected irregular regions of [geo.size] cells each.
  /// Returns a regionMap (cell index → region ID, 0-indexed).
  List<int> generateJigsawRegions(GridGeometry geo) {
    final n = geo.size;
    final total = geo.cellCount;
    const maxAttempts = 200;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final regionMap = List.filled(total, -1);
      final regionSizes = List.filled(n, 0);

      // Place one seed per region.
      final seeds = List.generate(total, (i) => i)..shuffle(_rng);
      final regionSeeds = seeds.take(n).toList();
      for (int r = 0; r < n; r++) {
        regionMap[regionSeeds[r]] = r;
        regionSizes[r] = 1;
      }

      int assigned = n;
      bool progress = true;

      while (assigned < total && progress) {
        progress = false;
        // Bias toward smaller regions so all regions converge on size n.
        final order = List.generate(n, (i) => i)
          ..shuffle(_rng)
          ..sort((a, b) => regionSizes[a].compareTo(regionSizes[b]));

        for (final regionId in order) {
          if (regionSizes[regionId] >= n) continue;

          final frontier = <int>{};
          for (int i = 0; i < total; i++) {
            if (regionMap[i] != regionId) continue;
            for (final nb in _orthogonalNeighbours(i, geo)) {
              if (regionMap[nb] == -1) frontier.add(nb);
            }
          }

          if (frontier.isEmpty) continue;
          final picks = frontier.toList()..shuffle(_rng);
          final pick = picks.first;
          regionMap[pick] = regionId;
          regionSizes[regionId]++;
          assigned++;
          progress = true;

          if (assigned >= total) break;
        }
      }

      if (assigned == total && regionSizes.every((s) => s == n)) {
        return regionMap;
      }
    }

    // Safe fallback: standard box regions (still valid Sudoku regions).
    return List.generate(total, (idx) => geo.boxOf(idx));
  }

  // ── Killer cages ────────────────────────────────────────────────────────────

  /// Partitions the grid into cages of size 2–5, computing sums from [solution].
  KillerCageConstraint generateKillerCages(
    GridGeometry geo,
    List<int> solution,
  ) {
    final total = geo.cellCount;
    final assigned = List.filled(total, false);
    final cages = <CageData>[];

    final order = List.generate(total, (i) => i)..shuffle(_rng);

    for (final start in order) {
      if (assigned[start]) continue;

      final targetSize = 2 + _rng.nextInt(4); // 2–5 cells
      final cells = [start];
      assigned[start] = true;

      while (cells.length < targetSize) {
        final cageValues = cells.map((c) => solution[c]).toSet();
        final candidates = cells
            .expand((c) => _orthogonalNeighbours(c, geo))
            .where((nb) => !assigned[nb])
            // Killer no-repeat rule: don't add a cell whose value is already
            // present in this cage (the solution would immediately conflict).
            .where((nb) => !cageValues.contains(solution[nb]))
            .toList();
        if (candidates.isEmpty) break;
        candidates.shuffle(_rng);
        final pick = candidates.first;
        cells.add(pick);
        assigned[pick] = true;
      }

      final sum = cells.map((c) => solution[c]).reduce((a, b) => a + b);
      cages.add(CageData(cells: cells, targetSum: sum));
    }

    return KillerCageConstraint(cages: cages);
  }

  // ── Thermometers ────────────────────────────────────────────────────────────

  /// Generates [count] non-overlapping thermometer paths of length 2–5
  /// that are strictly increasing in [solution].
  ThermoConstraint generateThermos(
    GridGeometry geo,
    List<int> solution, {
    int count = 5,
  }) {
    final used = <int>{};
    final thermos = <List<int>>[];
    int attempts = 0;

    while (thermos.length < count && attempts < count * 20) {
      attempts++;
      final thermo = _tryGrowThermo(geo, solution, used);
      if (thermo != null) {
        thermos.add(thermo);
        used.addAll(thermo);
      }
    }

    return ThermoConstraint(thermos: thermos);
  }

  List<int>? _tryGrowThermo(
    GridGeometry geo,
    List<int> solution,
    Set<int> used,
  ) {
    final total = geo.cellCount;
    final start = _rng.nextInt(total);
    if (used.contains(start)) return null;

    final path = [start];
    int current = start;

    final maxLen = 2 + _rng.nextInt(4); // 2–5 cells
    for (int step = 1; step < maxLen; step++) {
      final candidates = _orthogonalNeighbours(current, geo)
          .where((nb) => !used.contains(nb) && !path.contains(nb))
          .where((nb) => solution[nb] > solution[current])
          .toList();
      if (candidates.isEmpty) break;
      candidates.shuffle(_rng);
      current = candidates.first;
      path.add(current);
    }

    return path.length >= 2 ? path : null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<int> _orthogonalNeighbours(int idx, GridGeometry geo) {
    final r = geo.rowOf(idx);
    final c = geo.colOf(idx);
    final result = <int>[];
    if (r > 0) result.add(geo.indexOf(r - 1, c));
    if (r < geo.size - 1) result.add(geo.indexOf(r + 1, c));
    if (c > 0) result.add(geo.indexOf(r, c - 1));
    if (c < geo.size - 1) result.add(geo.indexOf(r, c + 1));
    return result;
  }
}
