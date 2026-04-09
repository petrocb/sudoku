import '../models/grid_geometry.dart';
import '../models/puzzle_config.dart';
import '../models/variant_constraint.dart';
import '../models/constraints/standard_regions_constraint.dart';
import '../models/constraints/diagonal_constraint.dart';
import '../models/constraints/hyper_window_constraint.dart';
import '../models/constraints/jigsaw_regions_constraint.dart';
import '../models/constraints/disjoint_groups_constraint.dart';
import '../models/constraints/anti_knight_constraint.dart';
import '../models/constraints/anti_king_constraint.dart';
import '../models/constraints/nonconsecutive_constraint.dart';
import '../models/constraints/killer_cage_constraint.dart';
import '../models/constraints/thermo_constraint.dart';

// ── Public types ──────────────────────────────────────────────────────────────

class CampaignLevel {
  final int number;
  final String title;
  final String description;
  final PuzzleConfig config;
  final int clues;

  const CampaignLevel({
    required this.number,
    required this.title,
    required this.description,
    required this.config,
    required this.clues,
  });
}

final List<CampaignLevel> madokuCampaign = _buildCampaign();

// ── Difficulty helpers ────────────────────────────────────────────────────────

/// t = 0.0 (easiest) → 1.0 (hardest)
String _diffLabel(double t) {
  if (t < 0.12) return 'Beginner';
  if (t < 0.25) return 'Easy';
  if (t < 0.42) return 'Medium';
  if (t < 0.58) return 'Hard';
  if (t < 0.74) return 'Expert';
  if (t < 0.88) return 'Master';
  return 'Grandmaster';
}

String _diffId(double t) {
  if (t < 0.33) return 'easy';
  if (t < 0.66) return 'medium';
  return 'hard';
}

int _tClues(GridGeometry geo, double t, {bool isKiller = false}) {
  if (isKiller) return 0;
  const easyRatio = 0.58;
  const hardRatio = 0.26;
  final ratio = easyRatio - (easyRatio - hardRatio) * t;
  final cells = geo.cellCount;
  return (cells * ratio).round().clamp(geo.size, cells - geo.size);
}

String _variantLabel(List<VariantConstraint> constraints) {
  final names = constraints
      .where((c) => c is! StandardRegionsConstraint)
      .map((c) {
        if (c is DiagonalConstraint) return 'Diagonal';
        if (c is HyperWindowConstraint) return 'Hyper';
        if (c is JigsawRegionsConstraint) return 'Jigsaw';
        if (c is DisjointGroupsConstraint) return 'Disjoint';
        if (c is AntiKnightConstraint) return 'Anti-Knight';
        if (c is AntiKingConstraint) return 'Anti-King';
        if (c is NonconsecutiveConstraint) return 'Non-Consec';
        if (c is KillerCageConstraint) return 'Killer';
        if (c is ThermoConstraint) return 'Thermo';
        return '';
      })
      .where((s) => s.isNotEmpty)
      .toList();
  return names.isEmpty ? 'Standard' : names.join(' + ');
}

// ── Builder ───────────────────────────────────────────────────────────────────

List<CampaignLevel> _buildCampaign() {
  final levels = <CampaignLevel>[];

  void chapter({
    required String name,
    required GridGeometry geo,
    required List<List<VariantConstraint>> variants,
    required int count,
    required double tStart,
    required double tEnd,
  }) {
    for (int i = 0; i < count; i++) {
      final n = levels.length + 1;
      final t = count == 1 ? tStart : tStart + (tEnd - tStart) * i / (count - 1);
      final constraints = variants[i % variants.length];
      final isKiller = constraints.any((c) => c is KillerCageConstraint);
      final clues = _tClues(geo, t, isKiller: isKiller);
      final varLabel = _variantLabel(constraints);
      final diff = _diffLabel(t);

      levels.add(CampaignLevel(
        number: n,
        title: '$name · $diff',
        description: '${geo.size}×${geo.size} · $varLabel · $diff',
        config: PuzzleConfig(
          geometry: geo,
          constraints: constraints,
          difficultyId: _diffId(t),
          seed: n * 9973 + 1337,
        ),
        clues: clues,
      ));
    }
  }

  // ── Constraint shorthands ─────────────────────────────────────────────────
  const std   = [StandardRegionsConstraint()];
  const diag  = [StandardRegionsConstraint(), DiagonalConstraint()];
  const hyper = [StandardRegionsConstraint(), HyperWindowConstraint()];
  const jig   = [StandardRegionsConstraint(), JigsawRegionsConstraint()];
  const disj  = [StandardRegionsConstraint(), DisjointGroupsConstraint()];
  const ak    = [StandardRegionsConstraint(), AntiKnightConstraint()];
  const akg   = [StandardRegionsConstraint(), AntiKingConstraint()];
  const nc    = [StandardRegionsConstraint(), NonconsecutiveConstraint()];
  const thermo = [StandardRegionsConstraint(), ThermoConstraint(thermos: [])];
  const killer = [StandardRegionsConstraint(), KillerCageConstraint(cages: [])];

  const diagAk     = [StandardRegionsConstraint(), DiagonalConstraint(),        AntiKnightConstraint()];
  const diagAkg    = [StandardRegionsConstraint(), DiagonalConstraint(),        AntiKingConstraint()];
  const diagNc     = [StandardRegionsConstraint(), DiagonalConstraint(),        NonconsecutiveConstraint()];
  const hyperAk    = [StandardRegionsConstraint(), HyperWindowConstraint(),     AntiKnightConstraint()];
  const hyperNc    = [StandardRegionsConstraint(), HyperWindowConstraint(),     NonconsecutiveConstraint()];
  const jigAk      = [StandardRegionsConstraint(), JigsawRegionsConstraint(),   AntiKnightConstraint()];
  const thermoAk   = [StandardRegionsConstraint(), ThermoConstraint(thermos: []), AntiKnightConstraint()];
  const thermoDiag = [StandardRegionsConstraint(), ThermoConstraint(thermos: []), DiagonalConstraint()];
  const killerDiag = [StandardRegionsConstraint(), KillerCageConstraint(cages: []), DiagonalConstraint()];
  const killerAk   = [StandardRegionsConstraint(), KillerCageConstraint(cages: []), AntiKnightConstraint()];
  const tripleA    = [StandardRegionsConstraint(), DiagonalConstraint(),        AntiKnightConstraint(), NonconsecutiveConstraint()];
  const tripleB    = [StandardRegionsConstraint(), HyperWindowConstraint(),     AntiKnightConstraint(), NonconsecutiveConstraint()];

  final g4  = GridGeometry.standard4x4;
  final g6  = GridGeometry.standard6x6;
  final g9  = GridGeometry.standard9x9;
  final g12 = GridGeometry.standard12x12;
  final g16 = GridGeometry.standard16x16;

  // ══════════════════════════════════════════════════════════════════════════
  //  4×4  — 30 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Warm-Up',    geo: g4, variants: [std],        count: 15, tStart: 0.00, tEnd: 0.30); //  1-15
  chapter(name: 'Mini',       geo: g4, variants: [std, diag],  count: 15, tStart: 0.30, tEnd: 0.75); // 16-30

  // ══════════════════════════════════════════════════════════════════════════
  //  6×6  — 40 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Six Classic',  geo: g6, variants: [std],           count: 20, tStart: 0.00, tEnd: 0.50); // 31-50
  chapter(name: 'Six Variant',  geo: g6, variants: [diag, ak, nc],  count: 15, tStart: 0.10, tEnd: 0.65); // 51-65
  chapter(name: 'Six Hard',     geo: g6, variants: [std, diag],     count:  5, tStart: 0.60, tEnd: 0.88); // 66-70

  // ══════════════════════════════════════════════════════════════════════════
  //  9×9 Standard  — 80 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Classic',  geo: g9, variants: [std], count: 15, tStart: 0.00, tEnd: 0.20); //  71-85
  chapter(name: 'Classic',  geo: g9, variants: [std], count: 15, tStart: 0.20, tEnd: 0.38); //  86-100
  chapter(name: 'Classic',  geo: g9, variants: [std], count: 20, tStart: 0.38, tEnd: 0.56); // 101-120
  chapter(name: 'Classic',  geo: g9, variants: [std], count: 18, tStart: 0.56, tEnd: 0.76); // 121-138
  chapter(name: 'Classic',  geo: g9, variants: [std], count: 12, tStart: 0.76, tEnd: 0.95); // 139-150

  // ══════════════════════════════════════════════════════════════════════════
  //  9×9 Single Variants  — 100 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Diagonal',   geo: g9, variants: [diag], count: 12, tStart: 0.12, tEnd: 0.45); // 151-162
  chapter(name: 'Diagonal',   geo: g9, variants: [diag], count: 13, tStart: 0.45, tEnd: 0.82); // 163-175
  chapter(name: 'Hyper',      geo: g9, variants: [hyper], count: 15, tStart: 0.12, tEnd: 0.75); // 176-190
  chapter(name: 'Jigsaw',     geo: g9, variants: [jig],  count: 15, tStart: 0.12, tEnd: 0.78); // 191-205
  chapter(name: 'Disjoint',   geo: g9, variants: [disj], count: 10, tStart: 0.18, tEnd: 0.70); // 206-215
  chapter(name: 'Anti-Knight',geo: g9, variants: [ak],   count: 12, tStart: 0.18, tEnd: 0.78); // 216-227
  chapter(name: 'Anti-King',  geo: g9, variants: [akg],  count: 12, tStart: 0.18, tEnd: 0.75); // 228-239
  chapter(name: 'Non-Consec', geo: g9, variants: [nc],   count: 11, tStart: 0.20, tEnd: 0.78); // 240-250

  // ══════════════════════════════════════════════════════════════════════════
  //  9×9 Overlays (Thermo / Killer)  — 60 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Thermo',       geo: g9, variants: [thermo], count: 20, tStart: 0.10, tEnd: 0.72); // 251-270
  chapter(name: 'Killer',       geo: g9, variants: [killer], count: 20, tStart: 0.08, tEnd: 0.72); // 271-290
  chapter(name: 'Thermo Expert',geo: g9, variants: [thermo], count: 10, tStart: 0.72, tEnd: 0.92); // 291-300
  chapter(name: 'Killer Expert',geo: g9, variants: [killer], count: 10, tStart: 0.72, tEnd: 0.92); // 301-310

  // ══════════════════════════════════════════════════════════════════════════
  //  9×9 Combinations  — 90 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Diag+AK',    geo: g9, variants: [diagAk],    count: 10, tStart: 0.28, tEnd: 0.80); // 311-320
  chapter(name: 'Diag+AKg',   geo: g9, variants: [diagAkg],   count:  7, tStart: 0.28, tEnd: 0.80); // 321-327
  chapter(name: 'Diag+NC',    geo: g9, variants: [diagNc],    count:  7, tStart: 0.30, tEnd: 0.82); // 328-334
  chapter(name: 'Hyper+AK',   geo: g9, variants: [hyperAk],   count:  7, tStart: 0.30, tEnd: 0.80); // 335-341
  chapter(name: 'Hyper+NC',   geo: g9, variants: [hyperNc],   count:  6, tStart: 0.30, tEnd: 0.80); // 342-347
  chapter(name: 'Jigsaw+AK',  geo: g9, variants: [jigAk],     count:  7, tStart: 0.32, tEnd: 0.82); // 348-354
  chapter(name: 'Thermo+Diag',geo: g9, variants: [thermoDiag],count:  8, tStart: 0.25, tEnd: 0.80); // 355-362
  chapter(name: 'Killer+Diag',geo: g9, variants: [killerDiag],count:  8, tStart: 0.22, tEnd: 0.80); // 363-370
  chapter(name: 'Killer+AK',  geo: g9, variants: [killerAk],  count:  7, tStart: 0.25, tEnd: 0.82); // 371-377
  chapter(name: 'Thermo+AK',  geo: g9, variants: [thermoAk],  count:  6, tStart: 0.30, tEnd: 0.82); // 378-383
  chapter(name: 'Triple A',   geo: g9, variants: [tripleA],   count:  6, tStart: 0.42, tEnd: 0.88); // 384-389
  chapter(name: 'Triple B',   geo: g9, variants: [tripleB],   count:  6, tStart: 0.42, tEnd: 0.88); // 390-395
  chapter(name: 'Master Mix', geo: g9,
      variants: [diag, hyper, jig, ak, nc, thermoDiag, killerDiag, diagAk],
      count: 5, tStart: 0.72, tEnd: 0.95);                                                          // 396-400

  // ══════════════════════════════════════════════════════════════════════════
  //  12×12  — 60 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Twelve',       geo: g12, variants: [std],   count: 18, tStart: 0.05, tEnd: 0.55); // 401-418
  chapter(name: 'Twelve Diag',  geo: g12, variants: [diag],  count: 10, tStart: 0.18, tEnd: 0.68); // 419-428
  chapter(name: 'Twelve AK',    geo: g12, variants: [ak],    count:  8, tStart: 0.22, tEnd: 0.72); // 429-436
  chapter(name: 'Twelve Thermo',geo: g12, variants: [thermo],count:  8, tStart: 0.15, tEnd: 0.68); // 437-444
  chapter(name: 'Twelve Killer',geo: g12, variants: [killer],count:  8, tStart: 0.12, tEnd: 0.68); // 445-452
  chapter(name: 'Twelve Hard',  geo: g12, variants: [std, diag, ak, nc],
      count: 8, tStart: 0.62, tEnd: 0.90);                                                         // 453-460

  // ══════════════════════════════════════════════════════════════════════════
  //  16×16  — 30 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Sixteen',      geo: g16, variants: [std],       count: 10, tStart: 0.08, tEnd: 0.50); // 461-470
  chapter(name: 'Sixteen Diag', geo: g16, variants: [diag],      count:  8, tStart: 0.20, tEnd: 0.65); // 471-478
  chapter(name: 'Sixteen Hard', geo: g16, variants: [std, diag], count: 12, tStart: 0.50, tEnd: 0.88); // 479-490

  // ══════════════════════════════════════════════════════════════════════════
  //  Grand Finale  — 10 levels
  // ══════════════════════════════════════════════════════════════════════════
  chapter(name: 'Grandmaster', geo: g9,
      variants: [tripleA, tripleB, killerDiag, thermoAk, killerAk],
      count: 5, tStart: 0.88, tEnd: 1.00);                                                          // 491-495
  chapter(name: 'Grandmaster', geo: g12,
      variants: [diagAk, thermo, killer],
      count: 3, tStart: 0.88, tEnd: 1.00);                                                          // 496-498
  chapter(name: 'Grandmaster', geo: g16,
      variants: [std, diag],
      count: 2, tStart: 0.92, tEnd: 1.00);                                                          // 499-500

  assert(levels.length == 500,
      'Campaign has ${levels.length} levels — expected 500. Check chapter counts.');

  return levels;
}
