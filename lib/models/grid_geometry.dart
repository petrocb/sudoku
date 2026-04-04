/// Geometric configuration for an N×N Sudoku grid with R×C box regions.
///
/// Works for any grid where [size] = [boxRows] × [boxCols]:
///   4×4 (2×2), 6×6 (2×3 or 3×2), 9×9 (3×3),
///   10×10 (2×5 or 5×2), 12×12 (3×4 or 2×6), 16×16 (4×4), 20×20 (4×5)
///
/// For Jigsaw variants, supply [regionMap] (cell index → region ID) to
/// override the standard box calculation.
class GridGeometry {
  final int size;      // N: number of symbols and grid dimension
  final int boxRows;   // rows per standard box region
  final int boxCols;   // cols per standard box region
  final List<int>? regionMap; // jigsaw: regionMap[idx] = region ID (null = standard)

  const GridGeometry({
    required this.size,
    required this.boxRows,
    required this.boxCols,
    this.regionMap,
  });

  int get cellCount => size * size;

  int rowOf(int idx) => idx ~/ size;
  int colOf(int idx) => idx % size;
  int indexOf(int row, int col) => row * size + col;

  /// Box/region index for a cell.
  /// Uses [regionMap] when set (jigsaw), otherwise uses standard box math.
  int boxOf(int idx) {
    if (regionMap != null) return regionMap![idx];
    final r = rowOf(idx);
    final c = colOf(idx);
    return (r ~/ boxRows) * (size ~/ boxCols) + (c ~/ boxCols);
  }

  List<int> rowIndicesOf(int idx) {
    final r = rowOf(idx);
    return List.generate(size, (c) => r * size + c);
  }

  List<int> colIndicesOf(int idx) {
    final c = colOf(idx);
    return List.generate(size, (r) => r * size + c);
  }

  /// All cells in the same box/region as [idx].
  List<int> boxIndicesOf(int idx) {
    if (regionMap != null) {
      final regionId = regionMap![idx];
      return [for (int i = 0; i < cellCount; i++) if (regionMap![i] == regionId) i];
    }
    final r = rowOf(idx);
    final c = colOf(idx);
    final br = (r ~/ boxRows) * boxRows;
    final bc = (c ~/ boxCols) * boxCols;
    final result = <int>[];
    for (int rr = br; rr < br + boxRows; rr++) {
      for (int cc = bc; cc < bc + boxCols; cc++) {
        result.add(rr * size + cc);
      }
    }
    return result;
  }

  List<List<int>> get rowRegions =>
      List.generate(size, (r) => List.generate(size, (c) => r * size + c));

  List<List<int>> get colRegions =>
      List.generate(size, (c) => List.generate(size, (r) => r * size + c));

  /// All box/region groups. Uses [regionMap] if set, otherwise standard boxes.
  List<List<int>> get boxRegions {
    if (regionMap != null) {
      final map = <int, List<int>>{};
      for (int i = 0; i < cellCount; i++) {
        map.putIfAbsent(regionMap![i], () => []).add(i);
      }
      final keys = map.keys.toList()..sort();
      return keys.map((k) => map[k]!).toList();
    }
    final numBoxRows = size ~/ boxRows;
    final numBoxCols = size ~/ boxCols;
    final regions = <List<int>>[];
    for (int br = 0; br < numBoxRows; br++) {
      for (int bc = 0; bc < numBoxCols; bc++) {
        final cells = <int>[];
        for (int r = br * boxRows; r < (br + 1) * boxRows; r++) {
          for (int c = bc * boxCols; c < (bc + 1) * boxCols; c++) {
            cells.add(r * size + c);
          }
        }
        regions.add(cells);
      }
    }
    return regions;
  }

  // ── Common presets ──────────────────────────────────────────────────────────
  static const standard4x4   = GridGeometry(size:  4, boxRows: 2, boxCols: 2);
  static const standard6x6   = GridGeometry(size:  6, boxRows: 2, boxCols: 3);
  static const standard9x9   = GridGeometry(size:  9, boxRows: 3, boxCols: 3);
  static const standard10x10 = GridGeometry(size: 10, boxRows: 2, boxCols: 5);
  static const standard12x12 = GridGeometry(size: 12, boxRows: 3, boxCols: 4);
  static const standard16x16 = GridGeometry(size: 16, boxRows: 4, boxCols: 4);
  static const standard20x20 = GridGeometry(size: 20, boxRows: 4, boxCols: 5);

  Map<String, dynamic> toJson() => {
        'size': size,
        'boxRows': boxRows,
        'boxCols': boxCols,
        if (regionMap != null) 'regionMap': regionMap,
      };

  static GridGeometry fromJson(Map<String, dynamic> json) {
    final rawMap = json['regionMap'] as List?;
    return GridGeometry(
      size: (json['size'] as num).toInt(),
      boxRows: (json['boxRows'] as num).toInt(),
      boxCols: (json['boxCols'] as num).toInt(),
      regionMap: rawMap?.map((e) => (e as num).toInt()).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GridGeometry &&
      size == other.size &&
      boxRows == other.boxRows &&
      boxCols == other.boxCols;

  @override
  int get hashCode => Object.hash(size, boxRows, boxCols);

  @override
  String toString() => '$size×$size (box $boxRows×$boxCols)';
}
