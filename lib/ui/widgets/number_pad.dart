import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final int gridSize;
  final void Function(int n) onNumber;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  const NumberPad({
    super.key,
    required this.gridSize,
    required this.onNumber,
    required this.onClear,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    // For grids larger than 9, use a compact grid layout instead of a Wrap
    final useGrid = gridSize > 9;

    Widget buttons = useGrid
        ? GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: (gridSize / 2).ceil(),
            childAspectRatio: 1.4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (int n = 1; n <= gridSize; n++)
                FilledButton.tonal(
                  onPressed: () => onNumber(n),
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text('$n', style: const TextStyle(fontSize: 12)),
                ),
            ],
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int n = 1; n <= gridSize; n++)
                FilledButton.tonal(
                  onPressed: () => onNumber(n),
                  child: Text('$n'),
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          buttons,
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onBackspace,
            child: const Text('⌫ Clear Cell'),
          ),
        ],
      ),
    );
  }
}
