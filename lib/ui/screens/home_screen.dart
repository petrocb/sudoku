import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
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
import '../../services/madoku_campaign.dart';
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

  // Campaign progress (number of completed levels, 0 = none completed)
  int _campaignProgress = 0;

  // Variant picker
  int _selectedGridIdx = 2; // 9×9 default
  final Set<_VariantId> _selectedVariants = {};
  int _variantDiffIdx = 1; // 0=easy 1=medium 2=hard

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadCampaignProgress();
  }

  Future<void> _loadCampaignProgress() async {
    final game = context.read<GameController>();
    final progress = await game.storage.loadCampaignProgress();
    if (mounted) setState(() => _campaignProgress = progress);
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

  Future<void> _startCampaignLevel(CampaignLevel level) async {
    final game = context.read<GameController>();
    final navigator = Navigator.of(context);
    await game.newCampaignLevel(level);
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute(builder: (_) => GameScreen(campaignLevel: level)),
    );
    // Reload progress in case it was updated while playing.
    if (mounted) _loadCampaignProgress();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Madoku'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Campaign'),
            Tab(text: 'Variants'),
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
          _buildCampaign(scheme),
          _buildVariantPicker(scheme),
        ],
      ),
    );
  }

  // ── Campaign tab ────────────────────────────────────────────────────────────

  Widget _buildCampaign(ColorScheme scheme) {
    final game = context.read<GameController>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Continue button (if there is a saved game)
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

          // Campaign header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Madoku Campaign',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_campaignProgress / ${madokuCampaign.length} levels completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: madokuCampaign.isEmpty
                      ? 0
                      : _campaignProgress / madokuCampaign.length,
                  backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.2),
                  color: scheme.onPrimaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Level list
          for (final level in madokuCampaign) ...[
            _LevelTile(
              level: level,
              status: level.number <= _campaignProgress
                  ? _LevelStatus.completed
                  : level.number == _campaignProgress + 1
                      ? _LevelStatus.current
                      : _LevelStatus.locked,
              // TODO(release): restore lock — onTap: level.number <= _campaignProgress + 1 ? () => _startCampaignLevel(level) : null,
              onTap: () => _startCampaignLevel(level),
            ),
            const SizedBox(height: 8),
          ],

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
                    _selectedVariants.removeWhere(
                      (v) => !_variantValidForGeo(v, _gridOptions[i].geo),
                    );
                  }),
                ),
            ],
          ),

          const SizedBox(height: 20),

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
}

// ── Level tile ────────────────────────────────────────────────────────────────

enum _LevelStatus { completed, current, locked }

class _LevelTile extends StatelessWidget {
  final CampaignLevel level;
  final _LevelStatus status;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLocked = status == _LevelStatus.locked;
    final isCurrent = status == _LevelStatus.current;
    final isCompleted = status == _LevelStatus.completed;

    final bgColor = isLocked
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : isCurrent
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;

    final textColor = isLocked
        ? scheme.onSurface.withValues(alpha: 0.4)
        : scheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? scheme.primary : scheme.outlineVariant,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${level.number}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textColor,
                        ),
                  ),
                  Text(
                    level.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Icon(Icons.check_circle, color: scheme.primary)
            else if (isCurrent)
              Icon(Icons.play_circle_outline, color: scheme.primary)
            else
              Icon(Icons.lock_outline, color: scheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
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
