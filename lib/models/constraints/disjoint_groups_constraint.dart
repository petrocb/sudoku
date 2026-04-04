import '../grid_geometry.dart';
import 'region_constraint.dart';

/// Disjoint Groups: cells at the same relative position within their
/// respective boxes must all contain different digits.
///
/// For a 9×9 grid with 3×3 boxes: all "top-left cells" of each box
/// must be different, all "top-center cells" must be different, etc.
/// This creates 9 extra groups of 9 cells each.
class DisjointGroupsConstraint extends RegionConstraint {
  static const kType = 'disjoint_groups';

  const DisjointGroupsConstraint();

  @override
  String get type => kType;

  @override
  List<List<int>> regions(GridGeometry geo) {
    // One region per "relative position" within a box
    // Position (pr, pc) where 0 ≤ pr < boxRows, 0 ≤ pc < boxCols
    final regions = <List<int>>[];
    for (int pr = 0; pr < geo.boxRows; pr++) {
      for (int pc = 0; pc < geo.boxCols; pc++) {
        final cells = <int>[];
        // Visit every box and pick the cell at relative position (pr, pc)
        for (int br = 0; br < geo.size ~/ geo.boxRows; br++) {
          for (int bc = 0; bc < geo.size ~/ geo.boxCols; bc++) {
            final row = br * geo.boxRows + pr;
            final col = bc * geo.boxCols + pc;
            cells.add(geo.indexOf(row, col));
          }
        }
        regions.add(cells);
      }
    }
    return regions;
  }

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static DisjointGroupsConstraint fromJson(Map<String, dynamic> json) =>
      const DisjointGroupsConstraint();
}
