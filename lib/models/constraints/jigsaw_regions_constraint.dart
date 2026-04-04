import '../grid_geometry.dart';
import '../variant_constraint.dart';

/// Marker constraint: tells the engine to generate irregular (jigsaw) box regions.
///
/// The engine detects this constraint, calls [ConstraintGenerator.generateJigsawRegions],
/// injects the resulting [regionMap] into a new [GridGeometry], and replaces this
/// marker with a [StandardRegionsConstraint] that automatically uses the regionMap.
///
/// The persisted [PuzzleConfig] (after generation) will therefore contain
/// [StandardRegionsConstraint] + a geometry with [regionMap] set — not this class.
class JigsawRegionsConstraint extends VariantConstraint {
  static const kType = 'jigsaw';

  const JigsawRegionsConstraint();

  @override
  String get type => kType;

  // No-ops: the engine replaces this before solving begins.
  @override
  Set<int> peersOf(int cellIndex, GridGeometry geo) => {};

  @override
  Set<int> findViolations(List<int> board, GridGeometry geo) => {};

  @override
  bool isPartiallyValid(List<int> board, GridGeometry geo, int lastPlaced) => true;

  @override
  Set<int> filterCandidates(
    Set<int> candidates,
    List<int> board,
    GridGeometry geo,
    int cellIndex,
  ) =>
      candidates;

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static JigsawRegionsConstraint fromJson(Map<String, dynamic> json) =>
      const JigsawRegionsConstraint();
}
