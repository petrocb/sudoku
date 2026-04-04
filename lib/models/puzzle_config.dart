import 'grid_geometry.dart';
import 'variant_constraint.dart';
import 'constraints/standard_regions_constraint.dart';
import 'constraints/diagonal_constraint.dart';
import 'constraints/hyper_window_constraint.dart';
import 'constraints/disjoint_groups_constraint.dart';
import 'constraints/anti_knight_constraint.dart';
import 'constraints/anti_king_constraint.dart';
import 'constraints/nonconsecutive_constraint.dart';
import 'constraints/killer_cage_constraint.dart';
import 'constraints/thermo_constraint.dart';
import 'constraints/jigsaw_regions_constraint.dart';

VariantConstraint _constraintFromJson(Map<String, dynamic> json) {
  switch (json['type'] as String) {
    case StandardRegionsConstraint.kType:
      return StandardRegionsConstraint.fromJson(json);
    case DiagonalConstraint.kType:
      return DiagonalConstraint.fromJson(json);
    case HyperWindowConstraint.kType:
      return HyperWindowConstraint.fromJson(json);
    case DisjointGroupsConstraint.kType:
      return DisjointGroupsConstraint.fromJson(json);
    case AntiKnightConstraint.kType:
      return AntiKnightConstraint.fromJson(json);
    case AntiKingConstraint.kType:
      return AntiKingConstraint.fromJson(json);
    case NonconsecutiveConstraint.kType:
      return NonconsecutiveConstraint.fromJson(json);
    case KillerCageConstraint.kType:
      return KillerCageConstraint.fromJson(json);
    case ThermoConstraint.kType:
      return ThermoConstraint.fromJson(json);
    case JigsawRegionsConstraint.kType:
      return JigsawRegionsConstraint.fromJson(json);
    default:
      throw ArgumentError('Unknown constraint type: ${json['type']}');
  }
}

/// Complete specification of a Madoku puzzle: grid shape + active variant rules.
class PuzzleConfig {
  final GridGeometry geometry;
  final List<VariantConstraint> constraints;
  final String difficultyId;
  final int seed;

  const PuzzleConfig({
    required this.geometry,
    required this.constraints,
    required this.difficultyId,
    required this.seed,
  });

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool hasConstraint<T extends VariantConstraint>() =>
      constraints.any((c) => c is T);

  T? constraint<T extends VariantConstraint>() =>
      constraints.whereType<T>().firstOrNull;

  /// Human-readable label shown in the app bar and elsewhere.
  String get displayName {
    final parts = <String>[];
    if (geometry.regionMap != null) parts.add('Jigsaw');
    if (hasConstraint<KillerCageConstraint>()) parts.add('Killer');
    if (hasConstraint<ThermoConstraint>()) parts.add('Thermo');
    if (hasConstraint<DiagonalConstraint>()) parts.add('Diagonal');
    if (hasConstraint<HyperWindowConstraint>()) parts.add('Hyper');
    if (hasConstraint<DisjointGroupsConstraint>()) parts.add('Disjoint');
    if (hasConstraint<AntiKnightConstraint>()) parts.add('Anti-Knight');
    if (hasConstraint<AntiKingConstraint>()) parts.add('Anti-King');
    if (hasConstraint<NonconsecutiveConstraint>()) parts.add('Non-Consec');
    if (hasConstraint<JigsawRegionsConstraint>()) parts.add('Jigsaw');
    if (parts.isEmpty) parts.add('Standard');
    return '${geometry.size}×${geometry.size} ${parts.join('+')}';
  }

  // ── Factory presets ─────────────────────────────────────────────────────────

  static PuzzleConfig standard({
    required GridGeometry geometry,
    required String difficultyId,
    required int seed,
  }) =>
      PuzzleConfig(
        geometry: geometry,
        constraints: const [StandardRegionsConstraint()],
        difficultyId: difficultyId,
        seed: seed,
      );

  static PuzzleConfig standard9x9({
    required String difficultyId,
    required int seed,
  }) =>
      standard(
        geometry: GridGeometry.standard9x9,
        difficultyId: difficultyId,
        seed: seed,
      );

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'geometry': geometry.toJson(),
        'constraints': constraints.map((c) => c.toJson()).toList(),
        'difficultyId': difficultyId,
        'seed': seed,
      };

  static PuzzleConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return PuzzleConfig(
        geometry: GridGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
        constraints: (json['constraints'] as List)
            .map((c) => _constraintFromJson(c as Map<String, dynamic>))
            .toList(),
        difficultyId: (json['difficultyId'] ?? 'medium').toString(),
        seed: (json['seed'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
