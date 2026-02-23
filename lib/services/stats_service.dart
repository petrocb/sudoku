import '../models/stats.dart';

class StatsService {
  Stats recordGameStarted(Stats stats, String difficultyId) {
    return stats.copyWith(
      gamesStarted: stats.gamesStarted + 1,
      lastPlayedIso: DateTime.now().toIso8601String(),
    );
  }

  Stats recordGameCompleted(Stats stats, String difficultyId, int elapsedMs, int hintsUsed) {
    final best = Map<String, int>.from(stats.bestTimeMsByDifficulty);
    final currentBest = best[difficultyId];
    if (currentBest == null || elapsedMs < currentBest) {
      best[difficultyId] = elapsedMs;
    }

    return stats.copyWith(
      gamesCompleted: stats.gamesCompleted + 1,
      bestTimeMsByDifficulty: best,
      totalHintsUsed: stats.totalHintsUsed + hintsUsed,
      lastPlayedIso: DateTime.now().toIso8601String(),
    );
  }
}