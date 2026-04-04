import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/difficulty.dart';
import '../../models/grid_geometry.dart';
import '../../models/puzzle_config.dart';
import '../../models/variant_constraint.dart';
import '../../models/constraints/standard_regions_constraint.dart';
import '../../models/constraints/diagonal_constraint.dart';
import '../../models/constraints/hyper_window_constraint.dart';
import '../../models/constraints/disjoint_groups_constraint.dart';
import '../../models/constraints/anti_knight_constraint.dart';
import '../../models/constraints/anti_king_constraint.dart';
import '../../models/constraints/nonconsecutive_constraint.dart';
import '../../models/constraints/killer_cage_constraint.dart';
import '../../models/constraints/thermo_constraint.dart';
import '../../models/constraints/jigsaw_regions_constraint.dart';
import '../../services/madoku_variant_selector.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../widgets/banner_ad_widget.dart';

// ── Grid size options ─────────────────────────────────────────────────────────

class _GridOption {
  final String label;
  final GridGeometry geo;
  const _GridOption(this.label, this.geo);
}

const _gridOptions = [
  _GridOption('4×4',   GridGeometry.standard4x4),
  _GridOption('6×6',   GridGeometry.standard6x6),
  _GridOption('9×9',   GridGeometry.standard9x9),
  _GridOption('12×12', GridGeometry.standard12x12),
  _GridOption('16×16', GridGeometry.standard16x16),
];

// ── Variant definitions ───────────────────────────────────────────────────────

enum _VariantId {
  diagonal, hyper, jigsaw, disjoint,
  killer, thermo,
  antiKnight, antiKing, nonConsec,
}

class _VariantOption {
  final _VariantId id;
  final String label;
  final String description;
  final VariantConstraint Function() build;

  const _VariantOption({
    required this.id,
    required this.label,
    required this.description,
    required this.build,
  });
}

final _allVariants = [
  _VariantOption(
    id: _VariantId.diagonal,
    label: 'Diagonal',
    description: 'Both diagonals unique',
    build: () => const DiagonalConstraint(),
  ),
  _VariantOption(
    id: _VariantId.hyper,
    label: 'Hyper',
    description: '4 inner windows unique (9×9)',
    build: () => const HyperWindowConstraint(),
  ),
  _VariantOption(
    id: _VariantId.jigsaw,
    label: 'Jigsaw',
    description: 'Irregular box regions',
    build: () => const JigsawRegionsConstraint(),
  ),
  _VariantOption(
    id: _VariantId.disjoint,
    label: 'Disjoint',
    description: 'Same box position unique',
    build: () => const DisjointGroupsConstraint(),
  ),
  _VariantOption(
    id: _VariantId.killer,
    label: 'Killer',
    description: 'Cage sum targets',
    build: () => const KillerCageConstraint(cages: []),
  ),
  _VariantOption(
    id: _VariantId.thermo,
    label: 'Thermo',
    description: 'Strictly increasing paths',
    build: () => const ThermoConstraint(thermos: []),
  ),
  _VariantOption(
    id: _VariantId.antiKnight,
    label: 'Anti-Knight',
    description: "Knight's move ≠ same digit",
    build: () => const AntiKnightConstraint(),
  ),
  _VariantOption(
    id: _VariantId.antiKing,
    label: 'Anti-King',
    description: "King's move ≠ same digit",
    build: () => const AntiKingConstraint(),
  ),
  _VariantOption(
    id: _VariantId.nonConsec,
    label: 'Non-Consec',
    description: 'Neighbours differ by >1',
    build: () => const NonconsecutiveConstraint(),
  ),
];

// ── Incompatibility rules ─────────────────────────────────────────────────────

/// Returns ids that should be disabled when [selected] is chosen.
Set<_VariantId> _incompatibleWith(_VariantId id) => switch (id) {
      _VariantId.jigsaw   => {_VariantId.hyper, _VariantId.disjoint},
      _VariantId.hyper    => {_VariantId.jigsaw},
      _VariantId.disjoint => {_VariantId.jigsaw},
      _               => {},
    };

bool _variantValidForGeo(_VariantId id, GridGeometry geo) => switch (id) {
      _VariantId.hyper => geo.size == 9 && geo.boxRows == 3,
      _                => true,
    };

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Quick Play
  double _customClues = Difficulty.medium.clues.toDouble();

  // Variant picker
  int _selectedGridIdx = 2; // 9×9 default
  final Set<_VariantId> _selectedVariants = {};
  int _variantDiffIdx = 1; // 0=easy 1=medium 2=hard

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  GridGeometry get _pickedGeo => _gridOptions[_selectedGridIdx].geo;

  Set<_VariantId> get _disabledVariants {
    final disabled = <_VariantId>{};
    for (final sel in _selectedVariants) {
      disabled.addAll(_incompatibleWith(sel));
    }
    for (final v in _allVariants) {
      if (!_variantValidForGeo(v.id, _pickedGeo)) disabled.add(v.id);
    }
    return disabled;
  }

  PuzzleConfig _buildVariantConfig(String difficultyId) {
    final geo = _pickedGeo;
    final constraints = <VariantConstraint>[const StandardRegionsConstraint()];
    for (final id in _selectedVariants) {
      final opt = _allVariants.firstWhere((v) => v.id == id);
      constraints.add(opt.build());
    }
    return PuzzleConfig(
      geometry: geo,
      constraints: constraints,
      difficultyId: difficultyId,
      seed: DateTime.now().microsecondsSinceEpoch,
    );
  }

  int get _variantClues {
    final geo = _pickedGeo;
    final diffId = ['easy', 'medium', 'hard'][_variantDiffIdx];
    // Killer: engine will prune to 0; others use ratio
    if (_selectedVariants.contains(_VariantId.killer)) return 0;
    return madokuClues(geo, diffId);
  }

  Future<void> _startVariantGame() async {
    final game = context.read<GameController>();
    final navigator = Navigator.of(context);
    final diffId = ['easy', 'medium', 'hard'][_variantDiffIdx];
    final config = _buildVariantConfig(diffId);
    await game.newGameWithConfig(config, clues: _variantClues);
    if (!mounted) return;
    navigator.push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  Future<void> _startMadokuGame(String diffId) async {
    final game = context.read<GameController>();
    final navigator = Navigator.of(context);
    final selector = MadokuVariantSelector();
    final config = selector.select(difficultyId: diffId);
    final clues = madokuClues(config.geometry, diffId);
    await game.newGameWithConfig(config, clues: clues);
    if (!mounted) return;
    navigator.push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Madoku'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Quick Play'),
            Tab(text: 'Variants'),
            Tab(text: 'Madoku Mode'),
          ],
        ),
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
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildQuickPlay(game),
          _buildVariantPicker(scheme),
          _buildMadokuMode(scheme),
        ],
      ),
    );
  }

  // ── Quick Play tab ──────────────────────────────────────────────────────────

  Widget _buildQuickPlay(GameController game) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<bool>(
            future: game.hasSavedGame(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue'),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await game.loadContinueGame();
                    if (!mounted) return;
                    navigator.push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                  },
                ),
              );
            },
          ),

          for (final d in Difficulty.all) ...[
            _CardButton(
              title: d.name,
              subtitle: d.subtitle,
              onTap: () async {
                final navigator = Navigator.of(context);
                await game.newGame(d);
                if (!mounted) return;
                navigator.push(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
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
              final navigator = Navigator.of(context);
              final d = Difficulty.custom(_customClues.round());
              await game.newGame(d);
              if (!mounted) return;
              navigator.push(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            },
            child: const Text('Start Custom Game'),
          ),

          const SizedBox(height: 16),
          const Center(child: BannerAdWidget()),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text('Stats'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Variant Picker tab ──────────────────────────────────────────────────────

  Widget _buildVariantPicker(ColorScheme scheme) {
    final disabled = _disabledVariants;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grid size
          Text('Grid Size', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < _gridOptions.length; i++)
                ChoiceChip(
                  label: Text(_gridOptions[i].label),
                  selected: _selectedGridIdx == i,
                  onSelected: (_) => setState(() {
                    _selectedGridIdx = i;
                    // Remove variants that became invalid for new size
                    _selectedVariants.removeWhere(
                      (v) => !_variantValidForGeo(v, _gridOptions[i].geo),
                    );
                  }),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Variant selection
          Text('Variants', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tap to combine. Incompatible options are greyed out.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in _allVariants)
                FilterChip(
                  label: Text(v.label),
                  tooltip: v.description,
                  selected: _selectedVariants.contains(v.id),
                  onSelected: disabled.contains(v.id)
                      ? null
                      : (sel) => setState(() {
                            if (sel) {
                              _selectedVariants.add(v.id);
                              // Remove any newly incompatible selections
                              _selectedVariants.removeWhere(
                                (id) => id != v.id &&
                                    _incompatibleWith(v.id).contains(id),
                              );
                            } else {
                              _selectedVariants.remove(v.id);
                            }
                          }),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Difficulty
          Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < 3; i++)
                ChoiceChip(
                  label: Text(['Easy', 'Medium', 'Hard'][i]),
                  selected: _variantDiffIdx == i,
                  onSelected: (_) => setState(() => _variantDiffIdx = i),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Config preview
          _ConfigPreviewCard(
            geo: _pickedGeo,
            variants: _selectedVariants
                .map((id) => _allVariants.firstWhere((v) => v.id == id).label)
                .toList(),
            scheme: scheme,
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Variant Game'),
            onPressed: _startVariantGame,
          ),

          const SizedBox(height: 16),
          const Center(child: BannerAdWidget()),
        ],
      ),
    );
  }

  // ── Madoku Mode tab ─────────────────────────────────────────────────────────

  Widget _buildMadokuMode(ColorScheme scheme) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer,
                  scheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Madoku Mode',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every puzzle is unique — the app randomly combines '
                  'grid sizes and variants so no two games feel the same.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Choose difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          for (final entry in [
            ('Easy Madoku',   'easy',   'Gentle variants, more clues'),
            ('Medium Madoku', 'medium', 'Balanced challenge'),
            ('Hard Madoku',   'hard',   'Fewer clues, tougher combos'),
          ]) ...[
            _CardButton(
              title: entry.$1,
              subtitle: entry.$3,
              onTap: () => _startMadokuGame(entry.$2),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What can appear?',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final label in [
                        '4×4–16×16',
                        'Killer',
                        'Thermo',
                        'Diagonal',
                        'Hyper',
                        'Jigsaw',
                        'Anti-Knight',
                        'Anti-King',
                        'Non-Consec',
                        'Disjoint',
                      ])
                        Chip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(child: BannerAdWidget()),
        ],
      ),
    );
  }
}

// ── Config preview card ───────────────────────────────────────────────────────

class _ConfigPreviewCard extends StatelessWidget {
  final GridGeometry geo;
  final List<String> variants;
  final ColorScheme scheme;

  const _ConfigPreviewCard({
    required this.geo,
    required this.variants,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final desc = variants.isEmpty
        ? 'Standard ${geo.size}×${geo.size}'
        : '${geo.size}×${geo.size} ${variants.join(' + ')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.grid_4x4, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card button ────────────────────────────────────────────────────────

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
                  Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
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
