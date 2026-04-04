import 'dart:math';

import '../models/grid_geometry.dart';
import '../models/puzzle_config.dart';
import '../models/variant_constraint.dart';
import '../models/constraints/standard_regions_constraint.dart';
import '../models/constraints/killer_cage_constraint.dart';
import '../models/constraints/thermo_constraint.dart';
import '../models/constraints/jigsaw_regions_constraint.dart';
import '../utils/puzzle_rules.dart';
import 'constraint_generator.dart';

class SudokuPuzzle {
  final List<int> puzzle;         // given cells (0 = empty)
  final List<int> solution;       // complete solution
  final int seed;
  /// Non-null when the engine modified the config during generation
  /// (e.g. Jigsaw regions injected, Killer/Thermo overlay built).
  /// Callers should use this over the config they passed in.
  final PuzzleConfig? resolvedConfig;

  SudokuPuzzle({
    required this.puzzle,
    required this.solution,
    required this.seed,
    this.resolvedConfig,
  });
}

class SudokuEngine {
  /// Legacy convenience — generates a standard 9×9 puzzle.
  SudokuPuzzle generate({required int clues, int? seed}) {
    final actualSeed = seed ?? DateTime.now().microsecondsSinceEpoch;
    final config = PuzzleConfig.standard9x9(difficultyId: 'custom', seed: actualSeed);
    return generateFromConfig(config, clues: clues);
  }

  /// Main entry point for all variant puzzle generation.
  SudokuPuzzle generateFromConfig(PuzzleConfig config, {required int clues}) {
    final needsOverlay = config.hasConstraint<KillerCageConstraint>() ||
        config.hasConstraint<ThermoConstraint>() ||
        config.hasConstraint<JigsawRegionsConstraint>();

    if (needsOverlay) return _generateWithOverlay(config, clues: clues);
    return _generateStandard(config, clues: clues);
  }

  // ── Standard generation ─────────────────────────────────────────────────────

  SudokuPuzzle _generateStandard(PuzzleConfig config, {required int clues}) {
    final geo = config.geometry;
    final rules = PuzzleRules(config);
    final rng = Random(config.seed);

    for (int attempt = 0; attempt < 40; attempt++) {
      final solution = _generateSolved(geo, rules, rng);
      final puzzle = List<int>.from(solution);
      final indices = List.generate(geo.cellCount, (i) => i)..shuffle(rng);

      for (final idx in indices) {
        if (_filledCount(puzzle) <= clues) break;
        final backup = puzzle[idx];
        puzzle[idx] = 0;
        if (_countSolutions(List<int>.from(puzzle), geo, rules, limit: 2) != 1) {
          puzzle[idx] = backup;
        }
      }

      if (_filledCount(puzzle) <= clues) {
        return SudokuPuzzle(puzzle: puzzle, solution: solution, seed: config.seed);
      }
    }

    final sol = _generateSolved(geo, rules, rng);
    return SudokuPuzzle(puzzle: List<int>.from(sol), solution: sol, seed: config.seed);
  }

  // ── Overlay generation (Jigsaw / Killer / Thermo) ──────────────────────────

  /// 1. If Jigsaw: generate irregular regions and inject into geometry.
  /// 2. Generate a base solution with standard region constraints only.
  /// 3. Build Killer/Thermo overlay data from that solution.
  /// 4. Prune given cells with all constraints active.
  /// 5. Return the fully-resolved config in [SudokuPuzzle.resolvedConfig].
  SudokuPuzzle _generateWithOverlay(PuzzleConfig config, {required int clues}) {
    final rng = Random(config.seed);
    final gen = ConstraintGenerator(seed: config.seed);

    // ── Step 1: resolve geometry (Jigsaw injects regionMap) ──────────────────
    GridGeometry effectiveGeo = config.geometry;
    List<VariantConstraint> effectiveConstraints = List.from(config.constraints);

    if (config.hasConstraint<JigsawRegionsConstraint>()) {
      final regionMap = gen.generateJigsawRegions(config.geometry);
      effectiveGeo = GridGeometry(
        size: config.geometry.size,
        boxRows: config.geometry.boxRows,
        boxCols: config.geometry.boxCols,
        regionMap: regionMap,
      );
      // Replace the marker with StandardRegionsConstraint (which picks up regionMap)
      effectiveConstraints = effectiveConstraints
          .where((c) => c is! JigsawRegionsConstraint)
          .toList();
      if (!effectiveConstraints.any((c) => c is StandardRegionsConstraint)) {
        effectiveConstraints.insert(0, const StandardRegionsConstraint());
      }
    }

    // ── Step 2: base solution (standard regions on effective geometry) ────────
    final baseConfig = PuzzleConfig(
      geometry: effectiveGeo,
      constraints: [const StandardRegionsConstraint()],
      difficultyId: config.difficultyId,
      seed: config.seed,
    );
    final baseRules = PuzzleRules(baseConfig);
    final solution = _generateSolved(effectiveGeo, baseRules, rng);

    // ── Step 3: build overlay constraint data from the solution ───────────────
    final killerIdx = effectiveConstraints.indexWhere((c) => c is KillerCageConstraint);
    final thermoIdx = effectiveConstraints.indexWhere((c) => c is ThermoConstraint);

    if (killerIdx != -1) {
      effectiveConstraints[killerIdx] = gen.generateKillerCages(effectiveGeo, solution);
    }
    if (thermoIdx != -1) {
      final count = _thermoCount(effectiveGeo.size);
      effectiveConstraints[thermoIdx] =
          gen.generateThermos(effectiveGeo, solution, count: count);
    }

    // ── Step 4: full config + prune ───────────────────────────────────────────
    final fullConfig = PuzzleConfig(
      geometry: effectiveGeo,
      constraints: effectiveConstraints,
      difficultyId: config.difficultyId,
      seed: config.seed,
    );
    final fullRules = PuzzleRules(fullConfig);

    final puzzle = List<int>.from(solution);
    // Killer provides all constraint via cage sums → target 0 given cells
    final targetClues = config.hasConstraint<KillerCageConstraint>() ? 0 : clues;
    final indices = List.generate(effectiveGeo.cellCount, (i) => i)..shuffle(rng);

    for (final idx in indices) {
      if (_filledCount(puzzle) <= targetClues) break;
      final backup = puzzle[idx];
      puzzle[idx] = 0;
      if (_countSolutions(List<int>.from(puzzle), effectiveGeo, fullRules, limit: 2) != 1) {
        puzzle[idx] = backup;
      }
    }

    return SudokuPuzzle(
      puzzle: puzzle,
      solution: solution,
      seed: fullConfig.seed,
      resolvedConfig: fullConfig,
    );
  }

  int _thermoCount(int gridSize) => switch (gridSize) {
        <= 4  => 2,
        <= 6  => 3,
        <= 9  => 5,
        <= 12 => 7,
        _     => 10,
      };

  // ── Core backtracker ─────────────────────────────────────────────────────────

  int _filledCount(List<int> b) => b.where((v) => v != 0).length;

  List<int> _generateSolved(GridGeometry geo, PuzzleRules rules, Random rng) {
    final board = List<int>.filled(geo.cellCount, 0);
    _fill(board, geo, rules, rng);
    return board;
  }

  bool _fill(List<int> board, GridGeometry geo, PuzzleRules rules, Random rng) {
    final idx = _pickBestEmpty(board, geo, rules);
    if (idx == -1) return true;

    final allValues = Set<int>.from(List.generate(geo.size, (i) => i + 1));
    final candidates = rules.filterCandidates(allValues, board, idx).toList()
      ..shuffle(rng);

    for (final v in candidates) {
      board[idx] = v;
      if (_fill(board, geo, rules, rng)) return true;
      board[idx] = 0;
    }
    return false;
  }

  int _pickBestEmpty(List<int> board, GridGeometry geo, PuzzleRules rules) {
    int bestIdx = -1;
    int bestCount = geo.size + 1;
    final allValues = Set<int>.from(List.generate(geo.size, (i) => i + 1));

    for (int i = 0; i < geo.cellCount; i++) {
      if (board[i] != 0) continue;
      final c = rules.filterCandidates(allValues, board, i).length;
      if (c < bestCount) {
        bestCount = c;
        bestIdx = i;
        if (bestCount == 1) return bestIdx;
      }
    }
    return bestIdx;
  }

  int _countSolutions(
    List<int> board,
    GridGeometry geo,
    PuzzleRules rules, {
    required int limit,
  }) {
    int count = 0;

    bool dfs() {
      final idx = _pickBestEmpty(board, geo, rules);
      if (idx == -1) {
        count++;
        return count >= limit;
      }

      final allValues = Set<int>.from(List.generate(geo.size, (i) => i + 1));
      for (final v in rules.filterCandidates(allValues, board, idx)) {
        board[idx] = v;
        if (dfs()) return true;
        board[idx] = 0;
      }
      return false;
    }

    dfs();
    return count;
  }
}
