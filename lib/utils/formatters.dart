String formatDuration(int ms) {
  final totalSec = (ms / 1000).floor();
  final minutes = totalSec ~/ 60;
  final seconds = totalSec % 60;

  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss';
}