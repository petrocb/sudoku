class Stats {
  final int gamesStarted;
  final int gamesCompleted;
  final Map<String, int> bestTimeMsByDifficulty; // id -> best ms
  final int totalHintsUsed;
  final String? lastPlayedIso;

  const Stats({
    required this.gamesStarted,
    required this.gamesCompleted,
    required this.bestTimeMsByDifficulty,
    required this.totalHintsUsed,
    required this.lastPlayedIso,
  });

  factory Stats.empty() => const Stats(
        gamesStarted: 0,
        gamesCompleted: 0,
        bestTimeMsByDifficulty: {},
        totalHintsUsed: 0,
        lastPlayedIso: null,
      );

  Stats copyWith({
    int? gamesStarted,
    int? gamesCompleted,
    Map<String, int>? bestTimeMsByDifficulty,
    int? totalHintsUsed,
    String? lastPlayedIso,
  }) {
    return Stats(
      gamesStarted: gamesStarted ?? this.gamesStarted,
      gamesCompleted: gamesCompleted ?? this.gamesCompleted,
      bestTimeMsByDifficulty: bestTimeMsByDifficulty ?? this.bestTimeMsByDifficulty,
      totalHintsUsed: totalHintsUsed ?? this.totalHintsUsed,
      lastPlayedIso: lastPlayedIso ?? this.lastPlayedIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesStarted': gamesStarted,
        'gamesCompleted': gamesCompleted,
        'bestTimeMsByDifficulty': bestTimeMsByDifficulty,
        'totalHintsUsed': totalHintsUsed,
        'lastPlayedIso': lastPlayedIso,
      };

  static Stats fromJson(Map<String, dynamic> json) {
    final raw = json['bestTimeMsByDifficulty'];
    final map = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final k = entry.key.toString();
        final v = (entry.value as num?)?.toInt();
        if (v != null) map[k] = v;
      }
    }

    return Stats(
      gamesStarted: (json['gamesStarted'] as num?)?.toInt() ?? 0,
      gamesCompleted: (json['gamesCompleted'] as num?)?.toInt() ?? 0,
      bestTimeMsByDifficulty: map,
      totalHintsUsed: (json['totalHintsUsed'] as num?)?.toInt() ?? 0,
      lastPlayedIso: json['lastPlayedIso']?.toString(),
    );
  }
}