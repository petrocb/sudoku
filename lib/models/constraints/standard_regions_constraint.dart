import '../grid_geometry.dart';
import 'region_constraint.dart';

/// Standard Sudoku: rows, columns, and boxes must all contain unique values.
/// Automatically adapts to any grid size and box shape, including jigsaw
/// grids (where GridGeometry.regionMap overrides standard box calculation).
class StandardRegionsConstraint extends RegionConstraint {
  static const kType = 'standard_regions';

  const StandardRegionsConstraint();

  @override
  String get type => kType;

  @override
  List<List<int>> regions(GridGeometry geo) => [
        ...geo.rowRegions,
        ...geo.colRegions,
        ...geo.boxRegions,
      ];

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static StandardRegionsConstraint fromJson(Map<String, dynamic> json) =>
      const StandardRegionsConstraint();
}
