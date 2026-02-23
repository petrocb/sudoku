import 'dart:math';

class SudokuPuzzle {
  final List<int> puzzle;   // 81
  final List<int> solution; // 81
  final int seed;

  SudokuPuzzle({required this.puzzle, required this.solution, required this.seed});
}

class SudokuEngine {
  SudokuPuzzle generate({required int clues, int? seed}) {
    final actualSeed = seed ?? DateTime.now().microsecondsSinceEpoch;
    final rng = Random(actualSeed);

    // Try multiple times (uniqueness pruning can get stuck for some clue counts)
    for (int attempt = 0; attempt < 40; attempt++) {
      final solution = _generateSolved(rng);
      final puzzle = List<int>.from(solution);

      final indices = List<int>.generate(81, (i) => i)..shuffle(rng);

      for (final idx in indices) {
        if (_filledCount(puzzle) <= clues) break;

        final backup = puzzle[idx];
        puzzle[idx] = 0;

        // Keep only puzzles with UNIQUE solution
        if (_countSolutions(List<int>.from(puzzle), limit: 2) != 1) {
          puzzle[idx] = backup;
        }
      }

      if (_filledCount(puzzle) <= clues) {
        return SudokuPuzzle(puzzle: puzzle, solution: solution, seed: actualSeed);
      }
    }

    // Fallback: always return something valid
    final sol = _generateSolved(rng);
    final puz = List<int>.from(sol);
    return SudokuPuzzle(puzzle: puz, solution: sol, seed: actualSeed);
  }

  int _filledCount(List<int> b) => b.where((v) => v != 0).length;

  List<int> _generateSolved(Random rng) {
    final board = List<int>.filled(81, 0);
    _fill(board, rng);
    return board;
  }

  bool _fill(List<int> board, Random rng) {
    final idx = _pickBestEmpty(board);
    if (idx == -1) return true;

    final candidates = _candidates(board, idx)..shuffle(rng);
    for (final v in candidates) {
      board[idx] = v;
      if (_fill(board, rng)) return true;
      board[idx] = 0;
    }
    return false;
  }

  int _pickBestEmpty(List<int> board) {
    int bestIdx = -1;
    int bestCount = 10;

    for (int i = 0; i < 81; i++) {
      if (board[i] != 0) continue;
      final c = _candidates(board, i).length;
      if (c < bestCount) {
        bestCount = c;
        bestIdx = i;
        if (bestCount == 1) return bestIdx;
      }
    }
    return bestIdx;
  }

  List<int> _candidates(List<int> board, int index) {
    if (board[index] != 0) return const [];
    final used = <int>{};

    final r = index ~/ 9;
    final c = index % 9;

    for (int cc = 0; cc < 9; cc++) used.add(board[r * 9 + cc]);
    for (int rr = 0; rr < 9; rr++) used.add(board[rr * 9 + c]);

    final br = (r ~/ 3) * 3;
    final bc = (c ~/ 3) * 3;
    for (int rr = br; rr < br + 3; rr++) {
      for (int cc = bc; cc < bc + 3; cc++) {
        used.add(board[rr * 9 + cc]);
      }
    }

    final out = <int>[];
    for (int v = 1; v <= 9; v++) {
      if (!used.contains(v)) out.add(v);
    }
    return out;
  }

  int _countSolutions(List<int> board, {required int limit}) {
    int count = 0;

    bool dfs() {
      final idx = _pickBestEmpty(board);
      if (idx == -1) {
        count++;
        return count >= limit;
      }

      final candidates = _candidates(board, idx);
      for (final v in candidates) {
        board[idx] = v;
        final stop = dfs();
        board[idx] = 0;
        if (stop) return true;
      }
      return false;
    }

    dfs();
    return count;
  }
}