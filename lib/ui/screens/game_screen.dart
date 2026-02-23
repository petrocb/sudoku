import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/difficulty.dart';
import '../../utils/formatters.dart';

import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../widgets/notes_toggle.dart';
import '../widgets/completion_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for completion event -> show dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<GameController>();
      _controller!.addListener(_onControllerChanged);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      c.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      c.onAppResumed();
    }
  }

  void _onControllerChanged() {
    final c = _controller;
    if (c == null) return;

    final completion = c.completion;
    if (completion == null) return;

    // Ensure dialog shown once
    c.clearCompletion();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionDialog(
        difficultyName: completion.difficultyName,
        timeTaken: completion.timeString,
        hintsUsed: completion.hintsUsed,
        onBackToHome: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // back to home
        },
        onNewGameSameDifficulty: () async {
          Navigator.of(context).pop(); // close dialog
          final s = c.state;
          if (s == null) return;
          final d = Difficulty.fromId(s.difficultyId, clues: s.clueCount);
          await c.newGame(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, _) {
        final s = game.state;

        return Scaffold(
          appBar: AppBar(
            title: Text(s == null
                ? 'Sudoku'
                : 'Sudoku • ${Difficulty.fromId(s.difficultyId, clues: s.clueCount).name}'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Abandon game',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await game.abandon();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: game.isLoading || s == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Time: ${formatDuration(s.elapsedMs)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              'Hints: ${s.hintsUsed}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      SudokuBoard(
                        given: s.given,
                        board: s.board,
                        notes: s.notes,
                        selectedIndex: s.selectedIndex,
                        conflicts: game.conflicts,
                        peerHighlights: game.peerHighlights,
                        sameNumberHighlights: game.sameNumberHighlights,
                        highlightNotesMask: game.highlightNotesMask,
                        onTapCell: (i) => game.selectCell(i),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: game.hint,
                              child: const Text('Hint'),
                            ),
                            OutlinedButton(
                              onPressed: game.clearAllUserInputs,
                              child: const Text('Clear All'),
                            ),
                            OutlinedButton(
                              onPressed: game.clearCell,
                              child: const Text('Clear Cell'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      NotesToggle(
                        isOn: s.notesMode,
                        onToggle: () => game.toggleNotesMode(),
                      ),

                      const SizedBox(height: 8),

                      NumberPad(
                        onNumber: (n) => game.enterNumber(n),
                        onClear: () => game.enterNumber(0), // sets to 0 if allowed
                        onBackspace: game.clearCell,
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
          ),
        );
      },
    );
  }
}