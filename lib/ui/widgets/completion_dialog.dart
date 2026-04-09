import 'package:flutter/material.dart';

class CompletionDialog extends StatelessWidget {
  final String difficultyName;
  final String timeTaken;
  final int hintsUsed;

  final VoidCallback onBackToHome;
  /// When non-null, shows a "Next Level" button instead of "New Game".
  final VoidCallback? onNextLevel;
  /// Only used when [onNextLevel] is null — starts a new game at same difficulty.
  final VoidCallback? onNewGameSameDifficulty;

  const CompletionDialog({
    super.key,
    required this.difficultyName,
    required this.timeTaken,
    required this.hintsUsed,
    required this.onBackToHome,
    this.onNextLevel,
    this.onNewGameSameDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Puzzle complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Difficulty', difficultyName),
          _row('Time', timeTaken),
          _row('Hints used', '$hintsUsed'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onBackToHome,
          child: const Text('Back to Home'),
        ),
        if (onNextLevel != null)
          FilledButton(
            onPressed: onNextLevel,
            child: const Text('Next Level'),
          )
        else if (onNewGameSameDifficulty != null)
          FilledButton(
            onPressed: onNewGameSameDifficulty,
            child: const Text('New Game'),
          ),
      ],
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(a)),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}