class GameState {
  final String difficultyId;
  final int clueCount;

  final List<int> given;    // 81
  final List<int> board;    // 81
  final List<int> solution; // 81
  final List<int> notes;    // 81 bitmask

  final int? selectedIndex;
  final bool notesMode;

  final int hintsUsed;
  final int elapsedMs;

  final String startedAtIso;
  final String lastSavedAtIso;

  final bool isCompleted;

  const GameState({
    required this.difficultyId,
    required this.clueCount,
    required this.given,
    required this.board,
    required this.solution,
    required this.notes,
    required this.selectedIndex,
    required this.notesMode,
    required this.hintsUsed,
    required this.elapsedMs,
    required this.startedAtIso,
    required this.lastSavedAtIso,
    required this.isCompleted,
  });

  GameState copyWith({
    String? difficultyId,
    int? clueCount,
    List<int>? given,
    List<int>? board,
    List<int>? solution,
    List<int>? notes,
    int? selectedIndex,
    bool? notesMode,
    int? hintsUsed,
    int? elapsedMs,
    String? startedAtIso,
    String? lastSavedAtIso,
    bool? isCompleted,
    bool clearSelectedIndex = false,
  }) {
    return GameState(
      difficultyId: difficultyId ?? this.difficultyId,
      clueCount: clueCount ?? this.clueCount,
      given: given ?? this.given,
      board: board ?? this.board,
      solution: solution ?? this.solution,
      notes: notes ?? this.notes,
      selectedIndex: clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
      notesMode: notesMode ?? this.notesMode,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      startedAtIso: startedAtIso ?? this.startedAtIso,
      lastSavedAtIso: lastSavedAtIso ?? this.lastSavedAtIso,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'difficultyId': difficultyId,
        'clueCount': clueCount,
        'given': given,
        'board': board,
        'solution': solution,
        'notes': notes,
        'selectedIndex': selectedIndex,
        'notesMode': notesMode,
        'hintsUsed': hintsUsed,
        'elapsedMs': elapsedMs,
        'startedAtIso': startedAtIso,
        'lastSavedAtIso': lastSavedAtIso,
        'isCompleted': isCompleted,
      };

  static GameState? fromJson(Map<String, dynamic> json) {
    List<int> toIntList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => (e as num).toInt()).toList(growable: false);
    }

    final given = toIntList(json['given']);
    final board = toIntList(json['board']);
    final solution = toIntList(json['solution']);
    final notes = toIntList(json['notes']);

    if (given.length != 81 || board.length != 81 || solution.length != 81 || notes.length != 81) {
      return null;
    }

    return GameState(
      difficultyId: (json['difficultyId'] ?? 'medium').toString(),
      clueCount: (json['clueCount'] as num?)?.toInt() ?? 34,
      given: given,
      board: board,
      solution: solution,
      notes: notes,
      selectedIndex: (json['selectedIndex'] as num?)?.toInt(),
      notesMode: json['notesMode'] == true,
      hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
      elapsedMs: (json['elapsedMs'] as num?)?.toInt() ?? 0,
      startedAtIso: (json['startedAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      lastSavedAtIso: (json['lastSavedAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      isCompleted: json['isCompleted'] == true,
    );
  }
}