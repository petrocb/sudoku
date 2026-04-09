import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../models/settings.dart';
import '../models/stats.dart';

class StorageService {
  static const _kGame = 'saved_game_v1';
  static const _kStats = 'stats_v1';
  static const _kSettings = 'settings_v1';

  Future<bool> hasGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kGame);
  }

  Future<void> clearGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGame);
  }

  Future<void> saveGame(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGame, jsonEncode(state.toJson()));
  }

  Future<GameState?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGame);
    if (raw == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    return GameState.fromJson(decoded);
  }

  Future<void> saveStats(Stats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStats, jsonEncode(stats.toJson()));
  }

  Future<Stats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStats);
    if (raw == null) return Stats.empty();

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return Stats.empty();
    return Stats.fromJson(decoded);
  }

  static const _kCampaignProgress = 'campaign_progress_v1';

  Future<int> loadCampaignProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCampaignProgress) ?? 0;
  }

  /// Saves [completedLevel] (1-based) if it is greater than the stored value.
  Future<void> saveCampaignProgress(int completedLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_kCampaignProgress) ?? 0;
    if (completedLevel > current) {
      await prefs.setInt(_kCampaignProgress, completedLevel);
    }
  }

  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null) return Settings.defaults();

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return Settings.defaults();
    return Settings.fromJson(decoded);
  }
}