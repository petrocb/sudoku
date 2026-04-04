import 'dart:math';

import '../models/grid_geometry.dart';
import '../models/puzzle_config.dart';
import '../models/variant_constraint.dart';
import '../models/constraints/standard_regions_constraint.dart';
import '../models/constraints/diagonal_constraint.dart';
import '../models/constraints/hyper_window_constraint.dart';
import '../models/constraints/disjoint_groups_constraint.dart';
import '../models/constraints/anti_knight_constraint.dart';
import '../models/constraints/anti_king_constraint.dart';
import '../models/constraints/nonconsecutive_constraint.dart';
import '../models/constraints/killer_cage_constraint.dart';
import '../models/constraints/thermo_constraint.dart';
import '../models/constraints/jigsaw_regions_constraint.dart';

/// Randomly assembles a [PuzzleConfig] from compatible Madoku variants.
///
/// Rules:
///   • Always includes [StandardRegionsConstraint].
///   • Picks one optional "region modifier" (Jigsaw, Diagonal, Hyper, Disjoint).
///   • Optionally adds one "overlay" (Killer or Thermo).
///   • Optionally adds one "negative" constraint (Anti-Knight, Anti-King,
///     Non-Consecutive) — only for grids ≤ 12×12.
///   • Hyper is only valid for grids with boxRows == 3 (i.e. 9×9).
///   • Jigsaw is incompatible with Hyper and Disjoint.
class MadokuVariantSelector {
  final Random _rng;

  MadokuVariantSelector({int? seed})
      : _rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);

  /// Returns a randomly selected [PuzzleConfig] ready for [SudokuEngine.generateFromConfig].
  PuzzleConfig select({required String difficultyId}) {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final geo = _pickGeometry();
    final constraints = _buildConstraints(geo);

    return PuzzleConfig(
      geometry: geo,
      constraints: constraints,
      difficultyId: difficultyId,
      seed: seed,
    );
  }

  // ── Geometry ────────────────────────────────────────────────────────────────

  GridGeometry _pickGeometry() {
    // Weighted distribution — 9×9 is most common
    const options = [
      (GridGeometry.standard4x4,  5),
      (GridGeometry.standard6x6,  10),
      (GridGeometry.standard9x9,  50),
      (GridGeometry.standard12x12, 25),
      (GridGeometry.standard16x16, 10),
    ];
    final total = options.fold(0, (sum, e) => sum + e.$2);
    var r = _rng.nextInt(total);
    for (final o in options) {
      r -= o.$2;
      if (r < 0) return o.$1;
    }
    return GridGeometry.standard9x9;
  }

  // ── Constraint assembly ─────────────────────────────────────────────────────

  List<VariantConstraint> _buildConstraints(GridGeometry geo) {
    final constraints = <VariantConstraint>[const StandardRegionsConstraint()];

    // 1. Region modifier (mutually exclusive)
    final regionMod = _pickRegionModifier(geo);
    if (regionMod != null) constraints.add(regionMod);

    final hasJigsaw = regionMod is JigsawRegionsConstraint;

    // 2. Overlay variant (Killer or Thermo) — 45% chance
    if (_rng.nextDouble() < 0.45) {
      final overlay = _pickOverlay(geo);
      if (overlay != null) constraints.add(overlay);
    }

    // 3. Negative constraint — 30% chance, only for ≤ 12×12
    if (geo.size <= 12 && _rng.nextDouble() < 0.30 && !hasJigsaw) {
      final neg = _pickNegative();
      constraints.add(neg);
    }

    return constraints;
  }

  VariantConstraint? _pickRegionModifier(GridGeometry geo) {
    final options = <VariantConstraint?>[];

    // Standard-only (no modifier) — weighted higher
    options.addAll([null, null, null]);

    options.add(const JigsawRegionsConstraint());

    if (geo.size >= 6) {
      options.add(const DiagonalConstraint());
      options.add(const DisjointGroupsConstraint());
    }

    // Hyper: requires boxRows == 3 (standard 9×9 layout)
    if (geo.boxRows == 3 && geo.size == 9) {
      options.add(const HyperWindowConstraint());
    }

    return options[_rng.nextInt(options.length)];
  }

  VariantConstraint? _pickOverlay(GridGeometry geo) {
    // Killer works on any size; Thermo only up to 16×16 (performance)
    if (geo.size <= 16) {
      return _rng.nextBool()
          ? const KillerCageConstraint(cages: [])
          : const ThermoConstraint(thermos: []);
    }
    return const KillerCageConstraint(cages: []);
  }

  VariantConstraint _pickNegative() {
    const options = [
      AntiKnightConstraint(),
      AntiKingConstraint(),
      NonconsecutiveConstraint(),
    ];
    return options[_rng.nextInt(options.length)];
  }
}

// ── Clue count helpers ────────────────────────────────────────────────────────

/// Returns a sensible number of given clues for [geo] at the given difficulty.
/// Killer puzzles always receive 0 (cages provide full information).
int madokuClues(GridGeometry geo, String difficultyId) {
  // Approximate ratio from classic 9×9 difficulties
  final ratio = switch (difficultyId) {
    'easy'   => 0.50,
    'hard'   => 0.31,
    'madoku' => 0.36,
    _        => 0.40, // medium / default
  };
  final cells = geo.cellCount;
  return (cells * ratio).round().clamp(geo.size, cells - geo.size);
}
