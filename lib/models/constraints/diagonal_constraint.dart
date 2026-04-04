import '../grid_geometry.dart';
import 'region_constraint.dart';

/// X-Sudoku: both main diagonals must also contain each digit exactly once.
class DiagonalConstraint extends RegionConstraint {
  static const kType = 'diagonal';

  const DiagonalConstraint();

  @override
  String get type => kType;

  @override
  List<List<int>> regions(GridGeometry geo) => [
        // Main diagonal (top-left → bottom-right)
        [for (int i = 0; i < geo.size; i++) geo.indexOf(i, i)],
        // Anti-diagonal (top-right → bottom-left)
        [for (int i = 0; i < geo.size; i++) geo.indexOf(i, geo.size - 1 - i)],
      ];

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static DiagonalConstraint fromJson(Map<String, dynamic> json) =>
      const DiagonalConstraint();
}
