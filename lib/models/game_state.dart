import 'puzzle_config.dart';

class GameState {
  final PuzzleConfig config;

  final String difficultyId;
  final int clueCount;

  final List<int> given;    // length = config.geometry.cellCount
  final List<int> board;    // length = config.geometry.cellCount
  final List<int> solution; // length = config.geometry.cellCount
  final List<int> notes;    // length = config.geometry.cellCount, bitmask per cell

  final int? selectedIndex;
  final bool notesMode;

  final int hintsUsed;
  final int elapsedMs;

  final String startedAtIso;
  final String lastSavedAtIso;

  final bool isCompleted;

  const GameState({
    required this.config,
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
    PuzzleConfig? config,
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
      config: config ?? this.config,
      difficultyId: difficultyId ?? this.difficultyId,
      clueCount: clueCount ?? this.clueCount,
      given: given ?? this.given,
      board: board ?? this.board,
      solution: solution ?? this.solution,
      notes: notes ?? this.notes,
      selectedIndex:
          clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
      notesMode: notesMode ?? this.notesMode,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      startedAtIso: startedAtIso ?? this.startedAtIso,
      lastSavedAtIso: lastSavedAtIso ?? this.lastSavedAtIso,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
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

    // Load config — fall back to standard 9×9 for legacy saves without 'config'
    final config = PuzzleConfig.fromJson(
          json['config'] is Map<String, dynamic>
              ? json['config'] as Map<String, dynamic>
              : null,
        ) ??
        PuzzleConfig.standard9x9(
          difficultyId: (json['difficultyId'] ?? 'medium').toString(),
          seed: (json['seed'] as num?)?.toInt() ?? 0,
        );

    final expected = config.geometry.cellCount;

    final given    = toIntList(json['given']);
    final board    = toIntList(json['board']);
    final solution = toIntList(json['solution']);
    final notes    = toIntList(json['notes']);

    if (given.length    != expected ||
        board.length    != expected ||
        solution.length != expected ||
        notes.length    != expected) {
      return null;
    }

    return GameState(
      config: config,
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
      startedAtIso:
          (json['startedAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      lastSavedAtIso:
          (json['lastSavedAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      isCompleted: json['isCompleted'] == true,
    );
  }
}
