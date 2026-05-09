import 'dart:async';

class TrekTimerService {
  Timer? _timer;
  final _durationController = StreamController<Duration>.broadcast();
  Duration _elapsed = Duration.zero;

  Stream<Duration> get durationStream => _durationController.stream;
  Duration get currentDuration => _elapsed;

  void start({Duration? initialDuration}) {
    if (initialDuration != null) {
      _elapsed = initialDuration;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed += const Duration(seconds: 1);
      _durationController.add(_elapsed);
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    start();
  }

  void stop() {
    _timer?.cancel();
    _elapsed = Duration.zero;
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
  }
}
