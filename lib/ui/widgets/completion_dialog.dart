import 'package:flutter/material.dart';

class CompletionDialog extends StatelessWidget {
  final String difficultyName;
  final String timeTaken;
  final int hintsUsed;

  final VoidCallback onBackToHome;
  final VoidCallback onNewGameSameDifficulty;

  const CompletionDialog({
    super.key,
    required this.difficultyName,
    required this.timeTaken,
    required this.hintsUsed,
    required this.onBackToHome,
    required this.onNewGameSameDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('✅ Puzzle complete!'),
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