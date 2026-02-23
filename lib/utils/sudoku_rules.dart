Set<int> peerCells(int index) {
  final r = index ~/ 9;
  final c = index % 9;

  final peers = <int>{};

  // row
  for (int cc = 0; cc < 9; cc++) peers.add(r * 9 + cc);
  // col
  for (int rr = 0; rr < 9; rr++) peers.add(rr * 9 + c);
  // box
  final br = (r ~/ 3) * 3;
  final bc = (c ~/ 3) * 3;
  for (int rr = br; rr < br + 3; rr++) {
    for (int cc = bc; cc < bc + 3; cc++) {
      peers.add(rr * 9 + cc);
    }
  }
  peers.remove(index);
  return peers;
}

Set<int> sameNumberCells(List<int> board, int number) {
  final out = <int>{};
  for (int i = 0; i < 81; i++) {
    if (board[i] == number) out.add(i);
  }
  return out;
}

Set<int> findConflicts(List<int> board) {
  final conflicts = <int>{};

  int rowOf(int i) => i ~/ 9;
  int colOf(int i) => i % 9;

  bool sameBox(int a, int b) {
    final ra = rowOf(a), ca = colOf(a);
    final rb = rowOf(b), cb = colOf(b);
    return (ra ~/ 3 == rb ~/ 3) && (ca ~/ 3 == cb ~/ 3);
  }

  for (int i = 0; i < 81; i++) {
    final v = board[i];
    if (v == 0) continue;

    for (int j = i + 1; j < 81; j++) {
      if (board[j] != v) continue;

      final sameRow = rowOf(i) == rowOf(j);
      final sameCol = colOf(i) == colOf(j);
      final sb = sameBox(i, j);

      if (sameRow || sameCol || sb) {
        conflicts.add(i);
        conflicts.add(j);
      }
    }
  }
  return conflicts;
}

bool isSolvedExactly(List<int> board, List<int> solution) {
  if (board.length != 81 || solution.length != 81) return false;
  for (int i = 0; i < 81; i++) {
    if (board[i] != solution[i]) return false;
  }
  return true;
}