import 'dart:async';

class TimerService {
  Timer? _timer;
  final Stopwatch _sw = Stopwatch();
  int _baseElapsedMs = 0;

  void start({required int initialElapsedMs, required void Function(int elapsedMs) onTick}) {
    stop();
    _baseElapsedMs = initialElapsedMs;
    _sw.reset();
    _sw.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      onTick(_baseElapsedMs + _sw.elapsedMilliseconds);
    });
  }

  void pause() {
    _sw.stop();
  }

  void resume() {
    if (!_sw.isRunning) _sw.start();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sw.stop();
    _sw.reset();
    _baseElapsedMs = 0;
  }
}