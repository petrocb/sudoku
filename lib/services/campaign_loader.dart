import 'dart:convert';
import 'package:flutter/services.dart';

import 'sudoku_engine.dart';

/// Loads pre-generated campaign puzzle JSON from bundled assets.
///
/// Assets are written by `tool/generate_campaign.dart` and live at
/// `assets/campaign/level_001.json` … `level_500.json`.
///
/// Returns null if the asset doesn't exist (caller should fall back to
/// live generation via [SudokuEngine]).
class CampaignLoader {
  static Future<SudokuPuzzle?> load(int levelNumber) async {
    final path =
        'assets/campaign/level_${levelNumber.toString().padLeft(3, '0')}.json';
    try {
      final raw = await rootBundle.loadString(path);
      return SudokuPuzzle.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
