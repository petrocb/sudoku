import '../grid_geometry.dart';
import 'region_constraint.dart';

/// Hyper Sudoku: four inner 3×3 "windows" also contain each digit once.
/// Only valid for grids where size ≥ 7 and boxRows/boxCols = 3.
/// The four windows sit one cell inside each corner box.
class HyperWindowConstraint extends RegionConstraint {
  static const kType = 'hyper_window';

  const HyperWindowConstraint();

  @override
  String get type => kType;

  @override
  List<List<int>> regions(GridGeometry geo) {
    final w = geo.boxRows; // window size = box rows (3 for 9×9)
    // Window top-left corners are at (1,1), (1, size-w-1), (size-w-1,1), (size-w-1,size-w-1)
    final starts = [
      (1, 1),
      (1, geo.size - w - 1),
      (geo.size - w - 1, 1),
      (geo.size - w - 1, geo.size - w - 1),
    ];
    return starts.map((s) {
      final cells = <int>[];
      for (int r = s.$1; r < s.$1 + w; r++) {
        for (int c = s.$2; c < s.$2 + w; c++) {
          cells.add(geo.indexOf(r, c));
        }
      }
      return cells;
    }).toList();
  }

  @override
  Map<String, dynamic> toJson() => {'type': kType};

  static HyperWindowConstraint fromJson(Map<String, dynamic> json) =>
      const HyperWindowConstraint();
}
