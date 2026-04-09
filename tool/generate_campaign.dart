// ignore_for_file: avoid_print
// dart run tool/generate_campaign.dart
library;

/// Pre-generates all 500 campaign levels and writes them to
/// assets/campaign/level_001.json … level_500.json.
///
/// Run from the project root:
///   dart run tool/generate_campaign.dart
///
/// The script is resumable — already-generated files are skipped.
/// If a puzzle takes longer than 30 s to generate it retries with
/// seed+1 until it succeeds within the time limit.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_application_1/services/madoku_campaign.dart';
import 'package:flutter_application_1/services/sudoku_engine.dart';
import 'package:flutter_application_1/models/puzzle_config.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> main() async {
  final outDir = Directory('assets/campaign');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final levels = madokuCampaign;
  print('Generating ${levels.length} campaign levels…\n');

  int generated = 0;
  int skipped   = 0;

  for (final level in levels) {
    final file = File(
      'assets/campaign/level_${level.number.toString().padLeft(3, '0')}.json',
    );

    if (file.existsSync()) {
      skipped++;
      continue;
    }

    final puzzle = await _generateWithRetry(
      config: level.config,
      clues:  level.clues,
      levelNumber: level.number,
    );

    file.writeAsStringSync(jsonEncode(puzzle.toJson()));
    generated++;
    print('[${level.number.toString().padLeft(3)}/${levels.length}] '
        '${level.title.padRight(28)} — done');
  }

  print('\nFinished. Generated: $generated  Skipped (already existed): $skipped');
}

// ── Timeout + retry logic ─────────────────────────────────────────────────────

Future<SudokuPuzzle> _generateWithRetry({
  required PuzzleConfig config,
  required int clues,
  required int levelNumber,
}) async {
  int seedOffset = 0;

  while (true) {
    final effectiveConfig = seedOffset == 0
        ? config
        : PuzzleConfig(
            geometry:     config.geometry,
            constraints:  config.constraints,
            difficultyId: config.difficultyId,
            seed:         config.seed + seedOffset,
          );

    final puzzle = await _generateInIsolate(effectiveConfig, clues)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => null,
        );

    if (puzzle != null) return puzzle;

    seedOffset++;
    print('[${levelNumber.toString().padLeft(3)}] timeout — retrying '
        'with seed offset $seedOffset');
  }
}

// ── Isolate wrapper ───────────────────────────────────────────────────────────

Future<SudokuPuzzle?> _generateInIsolate(
  PuzzleConfig config,
  int clues,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_isolateEntry, [receivePort.sendPort, config, clues]);
  final result = await receivePort.first;
  if (result is SudokuPuzzle) return result;
  return null;
}

void _isolateEntry(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final config   = args[1] as PuzzleConfig;
  final clues    = args[2] as int;

  try {
    final puzzle = SudokuEngine().generateFromConfig(config, clues: clues);
    sendPort.send(puzzle);
  } catch (e) {
    sendPort.send(null);
  }
}
