import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final void Function(int n) onNumber;
  final VoidCallback onClear;     // optional (not used much)
  final VoidCallback onBackspace; // clear selected cell

  const NumberPad({
    super.key,
    required this.onNumber,
    required this.onClear,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (int n = 1; n <= 9; n++)
            FilledButton.tonal(
              onPressed: () => onNumber(n),
              child: Text('$n'),
            ),
          OutlinedButton(
            onPressed: onBackspace,
            child: const Text('⌫ Clear Cell'),
          ),
        ],
      ),
    );
  }
}