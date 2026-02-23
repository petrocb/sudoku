import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/difficulty.dart';
import '../models/game_state.dart';

import '../services/storage_service.dart';
import '../services/sudoku_engine.dart';
import '../services/timer_service.dart';

import '../controllers/stats_controller.dart';
import '../controllers/settings_controller.dart';

import '../utils/sudoku_rules.dart';
import '../utils/formatters.dart';

class CompletionInfo {
  final int elapsedMs;
  final int hintsUsed;
  final String difficultyName;

  CompletionInfo({
    required this.elapsedMs,
    required this.hintsUsed,
    required this.difficultyName,
  });

  String get timeString => formatDuration(elapsedMs);
}

class GameController extends ChangeNotifier {
  final StorageService storage;
  final SudokuEngine engine;
  final TimerService timer;

  final StatsController stats;
  final SettingsController settings;

  GameState? _state;
  bool _loading = false;

  Set<int> _conflicts = {};
  Set<int> _peers = {};
  Set<int> _sameNumbers = {};
  int _highlightNotesMask = 0;

  CompletionInfo? _completion;

  int _lastPersistTickMs = 0;

  GameController({
    required this.storage,
    required this.engine,
    required this.timer,
    required this.stats,
    required this.settings,
  });

  GameState? get state => _state;
  bool get isLoading => _loading;

  Set<int> get conflicts => _conflicts;
  Set<int> get peerHighlights => _peers;
  Set<int> get sameNumberHighlights => _sameNumbers;
  int get highlightNotesMask => _highlightNotesMask;

  CompletionInfo? get completion => _completion;

  bool get canContinue => _state != null;

  Future<bool> hasSavedGame() => storage.hasGame();

  Future<void> loadContinueGame() async {
    _loading = true;
    notifyListeners();

    final loaded = await storage.loadGame();
    if (loaded == null || loaded.isCompleted) {
      await storage.clearGame();
      _state = null;
      _loading = false;
      notifyListeners();
      return;
    }

    _state = loaded;
    _recomputeDerived();

    _startTimer();
    _loading = false;
    notifyListeners();
  }

  Future<void> newGame(Difficulty d) async {
    _loading = true;
    notifyListeners();

    // allow UI to paint a spinner
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final puzzle = engine.generate(clues: d.clues);
    final now = DateTime.now().toIso8601String();

    _state = GameState(
      difficultyId: d.id,
      clueCount: d.clues,
      given: List<int>.from(puzzle.puzzle),
      board: List<int>.from(puzzle.puzzle),
      solution: List<int>.from(puzzle.solution),
      notes: List<int>.filled(81, 0),
      selectedIndex: null,
      notesMode: false,
      hintsUsed: 0,
      elapsedMs: 0,
      startedAtIso: now,
      lastSavedAtIso: now,
      isCompleted: false,
    );

    _recomputeDerived();
    await stats.recordStarted(d.id);

    _startTimer();
    _loading = false;

    await _persist(force: true);
    notifyListeners();
  }

  Future<void> abandon() async {
    timer.stop();
    _state = null;
    _completion = null;
    _conflicts = {};
    _peers = {};
    _sameNumbers = {};
    _highlightNotesMask = 0;
    await storage.clearGame();
    notifyListeners();
  }

  void selectCell(int index) {
    if (_state == null) return;
    _state = _state!.copyWith(selectedIndex: index);
    _recomputeHighlightsOnly();
    notifyListeners();
  }

  Future<void> toggleNotesMode() async {
    if (_state == null) return;
    _state = _state!.copyWith(notesMode: !_state!.notesMode);
    _haptic();
    await _persist(force: true);
    notifyListeners();
  }

Future<void> enterNumber(int n) async {
  final s = _state;
  if (s == null) return;
  final idx = s.selectedIndex;
  if (idx == null) return;
  if (s.given[idx] != 0) return;

  if (s.notesMode) {
    await toggleNote(n);
    return;
  }

  // If n == 0, treat as clear (same as clearCell)
  if (n == 0) {
    await clearCell();
    return;
  }

  final newBoard = List<int>.from(s.board);
  newBoard[idx] = n;

  // Clear notes for that cell when setting a value
  final newNotes = List<int>.from(s.notes);
  newNotes[idx] = 0;

  // NEW: remove note 'n' from all peer cells (row/col/box)
  _removeNoteFromPeers(
    idx: idx,
    number: n,
    given: s.given,
    board: newBoard,
    notes: newNotes,
  );

  _state = s.copyWith(
    board: newBoard,
    notes: newNotes,
    lastSavedAtIso: DateTime.now().toIso8601String(),
  );

  _haptic();
  _recomputeDerived();
  await _persist(force: true);
  await _maybeComplete();
  notifyListeners();
}

  Future<void> clearCell() async {
    final s = _state;
    if (s == null) return;
    final idx = s.selectedIndex;
    if (idx == null) return;
    if (s.given[idx] != 0) return;

    final newBoard = List<int>.from(s.board);
    newBoard[idx] = 0;

    final newNotes = List<int>.from(s.notes);
    newNotes[idx] = 0;

    _state = s.copyWith(
      board: newBoard,
      notes: newNotes,
      lastSavedAtIso: DateTime.now().toIso8601String(),
    );

    _haptic();
    _recomputeDerived();
    await _persist(force: true);
    notifyListeners();
  }

  Future<void> toggleNote(int n) async {
    final s = _state;
    if (s == null) return;
    final idx = s.selectedIndex;
    if (idx == null) return;
    if (s.given[idx] != 0) return;
    if (s.board[idx] != 0) return; // no notes on filled cells

    final newNotes = List<int>.from(s.notes);
    final mask = newNotes[idx];
    final bit = 1 << n;
    newNotes[idx] = mask ^ bit;

    _state = s.copyWith(
      notes: newNotes,
      lastSavedAtIso: DateTime.now().toIso8601String(),
    );

    _haptic();
    _recomputeHighlightsOnly();
    await _persist(force: true);
    notifyListeners();
  }

  Future<void> hint() async {
    final s = _state;
    if (s == null) return;

    // pick first empty editable
    int idx = -1;
    for (int i = 0; i < 81; i++) {
      if (s.given[i] == 0 && s.board[i] == 0) {
        idx = i;
        break;
      }
    }
    if (idx == -1) return;

final newBoard = List<int>.from(s.board);
newBoard[idx] = s.solution[idx];
final newNotes = List<int>.from(s.notes);
newNotes[idx] = 0;

final n = s.solution[idx];
_removeNoteFromPeers(
  idx: idx,
  number: n,
  given: s.given,
  board: newBoard,
  notes: newNotes,
);
    _state = s.copyWith(
      board: newBoard,
      notes: newNotes,
      selectedIndex: idx,
      hintsUsed: s.hintsUsed + 1,
      lastSavedAtIso: DateTime.now().toIso8601String(),
    );

    _haptic();
    _recomputeDerived();
    await _persist(force: true);
    await _maybeComplete();
    notifyListeners();
  }

  Future<void> clearAllUserInputs() async {
    final s = _state;
    if (s == null) return;

    final newBoard = List<int>.from(s.board);
    final newNotes = List<int>.from(s.notes);

    for (int i = 0; i < 81; i++) {
      if (s.given[i] == 0) {
        newBoard[i] = 0;
        newNotes[i] = 0;
      }
    }

    _state = s.copyWith(
      board: newBoard,
      notes: newNotes,
      lastSavedAtIso: DateTime.now().toIso8601String(),
      clearSelectedIndex: true,
    );

    _haptic();
    _recomputeDerived();
    await _persist(force: true);
    notifyListeners();
  }

  // Called by GameScreen on lifecycle changes
  Future<void> onAppPaused() async {
    timer.pause();
    await _persist(force: true);
  }

  void onAppResumed() {
    timer.resume();
  }

  // GameScreen uses this after showing completion dialog
  void clearCompletion() {
    _completion = null;
  }

  // ---- Internal helpers ----
  void _removeNoteFromPeers({
  required int idx,
  required int number,
  required List<int> given,
  required List<int> board,
  required List<int> notes,
}) {
  final bit = 1 << number;
  final peers = peerCells(idx); // from utils/sudoku_rules.dart

  for (final p in peers) {
    // only editable, empty cells can have notes
    if (given[p] != 0) continue;
    if (board[p] != 0) continue;

    final mask = notes[p];
    if ((mask & bit) != 0) {
      notes[p] = mask & ~bit; // remove that note
    }
  }
}

  void _startTimer() {
    final s = _state;
    if (s == null) return;

    _lastPersistTickMs = s.elapsedMs;

    timer.start(
      initialElapsedMs: s.elapsedMs,
      onTick: (elapsedMs) async {
        final current = _state;
        if (current == null) return;
        if (current.isCompleted) return;

        _state = current.copyWith(elapsedMs: elapsedMs);

        // Persist timer occasionally (every 5 seconds) to survive abrupt closes
        if ((elapsedMs - _lastPersistTickMs).abs() >= 5000) {
          _lastPersistTickMs = elapsedMs;
          await _persist(force: false);
        }

        notifyListeners();
      },
    );
  }

  void _recomputeDerived() {
    final s = _state;
    if (s == null) return;

    _conflicts = settings.showConflicts ? findConflicts(s.board) : {};
    _recomputeHighlightsOnly();
  }

  void _recomputeHighlightsOnly() {
    final s = _state;
    if (s == null) return;

    final idx = s.selectedIndex;
    _peers = idx == null ? {} : peerCells(idx);

    final v = (idx == null) ? 0 : s.board[idx];
    if (v != 0) {
      _sameNumbers = sameNumberCells(s.board, v);
      _highlightNotesMask = (1 << v);
    } else {
      _sameNumbers = {};
      _highlightNotesMask = 0;
    }
  }

  Future<void> _persist({required bool force}) async {
    final s = _state;
    if (s == null) return;
    if (s.isCompleted) return;

    // Save immediately for moves; timer saves can be throttled (force=false).
    // For v1 we still save on each tick occasionally and always on force.
    final nowIso = DateTime.now().toIso8601String();
    final updated = s.copyWith(lastSavedAtIso: nowIso);
    _state = updated;

    await storage.saveGame(updated);
  }

  Future<void> _maybeComplete() async {
    final s = _state;
    if (s == null) return;

    if (settings.showConflicts && _conflicts.isNotEmpty) return;
    if (s.board.any((v) => v == 0)) return;

    if (!isSolvedExactly(s.board, s.solution)) return;

    // Completed
    timer.stop();

    final diff = Difficulty.fromId(s.difficultyId, clues: s.clueCount);

    _state = s.copyWith(isCompleted: true);
    await storage.clearGame();
    await stats.recordCompleted(diff.id, s.elapsedMs, s.hintsUsed);

    _completion = CompletionInfo(
      elapsedMs: s.elapsedMs,
      hintsUsed: s.hintsUsed,
      difficultyName: diff.name,
    );
  }

  void _haptic() {
    if (!settings.haptics) return;
    HapticFeedback.selectionClick();
  }
}