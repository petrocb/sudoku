import 'package:flutter/foundation.dart';
import '../models/stats.dart';
import '../services/storage_service.dart';
import '../services/stats_service.dart';

class StatsController extends ChangeNotifier {
  final StorageService _storage;
  final StatsService _service;

  Stats _stats = Stats.empty();
  bool _loaded = false;

  StatsController(this._storage, this._service);

  Stats get stats => _stats;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _stats = await _storage.loadStats();
    _loaded = true;
    notifyListeners();
  }

  Future<void> recordStarted(String difficultyId) async {
    _stats = _service.recordGameStarted(_stats, difficultyId);
    notifyListeners();
    await _storage.saveStats(_stats);
  }

  Future<void> recordCompleted(String difficultyId, int elapsedMs, int hintsUsed) async {
    _stats = _service.recordGameCompleted(_stats, difficultyId, elapsedMs, hintsUsed);
    notifyListeners();
    await _storage.saveStats(_stats);
  }
}