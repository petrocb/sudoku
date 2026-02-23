import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stats_controller.dart';
import '../../utils/formatters.dart';
import '../../models/difficulty.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsController>(
      builder: (context, statsCtrl, _) {
        final s = statsCtrl.stats;

        String bestTime(String id) {
          final ms = s.bestTimeMsByDifficulty[id];
          return ms == null ? '—' : formatDuration(ms);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Stats'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatRow(label: 'Games started', value: '${s.gamesStarted}'),
                  _StatRow(label: 'Games completed', value: '${s.gamesCompleted}'),
                  _StatRow(label: 'Total hints used', value: '${s.totalHintsUsed}'),
                  const SizedBox(height: 16),
                  Text('Best times', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _StatRow(label: Difficulty.easy.name, value: bestTime(Difficulty.easy.id)),
                  _StatRow(label: Difficulty.medium.name, value: bestTime(Difficulty.medium.id)),
                  _StatRow(label: Difficulty.hard.name, value: bestTime(Difficulty.hard.id)),
                  _StatRow(label: 'Custom', value: bestTime('custom')),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}