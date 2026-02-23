class Difficulty {
  final String id; // easy | medium | hard | custom
  final String name;
  final String subtitle;
  final int clues;

  const Difficulty({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.clues,
  });

  static const int minClues = 22;
  static const int maxClues = 60;

  static const easy = Difficulty(
    id: 'easy',
    name: 'Easy',
    subtitle: 'More starting numbers',
    clues: 40,
  );

  static const medium = Difficulty(
    id: 'medium',
    name: 'Medium',
    subtitle: 'A bit of thinking',
    clues: 34,
  );

  static const hard = Difficulty(
    id: 'hard',
    name: 'Hard',
    subtitle: 'Less help, more logic',
    clues: 28,
  );

  static const all = <Difficulty>[easy, medium, hard];

  static Difficulty custom(int clues) {
    final clamped = clues.clamp(minClues, maxClues);
    return Difficulty(
      id: 'custom',
      name: 'Custom',
      subtitle: '$clamped filled squares',
      clues: clamped,
    );
  }

  static Difficulty fromId(String id, {int? clues}) {
    switch (id) {
      case 'easy':
        return easy;
      case 'hard':
        return hard;
      case 'medium':
        return medium;
      case 'custom':
        return custom(clues ?? medium.clues);
      default:
        return medium;
    }
  }
}