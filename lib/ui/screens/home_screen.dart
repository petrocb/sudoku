import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/difficulty.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _customClues = Difficulty.medium.clues.toDouble();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Choose a mode to start playing.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),

              FutureBuilder<bool>(
                future: game.hasSavedGame(),
                builder: (context, snap) {
                  final hasSave = snap.data == true;
                  if (!hasSave) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Continue'),
                        onPressed: () async {
                          await game.loadContinueGame();
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              for (final d in Difficulty.all) ...[
                _CardButton(
                  title: d.name,
                  subtitle: d.subtitle,
                  onTap: () async {
                    await game.newGame(d);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 6),
              Text('Custom', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              Text('Filled squares: ${_customClues.round()}'),
              Slider(
                value: _customClues,
                min: Difficulty.minClues.toDouble(),
                max: Difficulty.maxClues.toDouble(),
                divisions: Difficulty.maxClues - Difficulty.minClues,
                label: _customClues.round().toString(),
                onChanged: (v) => setState(() => _customClues = v),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final d = Difficulty.custom(_customClues.round());
                  await game.newGame(d);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                },
                child: const Text('Start Custom Game'),
              ),

              const Spacer(),

              OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('Stats'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CardButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}