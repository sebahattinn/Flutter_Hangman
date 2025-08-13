import 'dart:async';
import 'dart:ui';
import 'package:get/get.dart';

class UsecaseController extends GetxController {
  
  final RxInt roundSeconds = 45.obs;

  /// Timer kısımları
  final RxInt secondsLeft = 45.obs;
  final RxBool isRunning = false.obs;
  final RxBool isPaused = false.obs;

  Timer? _timer;
  VoidCallback? _onTimeout;

  /// Start (or restart) the round timer
  void startRoundTimer({int? seconds, VoidCallback? onTimeout}) {
    cancelTimer();

    final total = seconds ?? roundSeconds.value;
    secondsLeft.value = total;
    _onTimeout = onTimeout;

    isRunning.value = true;
    isPaused.value = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = secondsLeft.value - 1;
      secondsLeft.value = next;
      if (next <= 0) {
        cancelTimer();
        _onTimeout?.call();
      }
    });
  }

  /// Pause the timer Bu kısım bug'lı çünkü pause yapınca tekrar başlatamıyorum
  void pauseTimer() {
    if (!isRunning.value || isPaused.value) return;
    _timer?.cancel();
    isPaused.value = true;
    isRunning.value = false;
  }

  /// Durduğu yerden devam etmesi kodu
  void resumeTimer() {
    if (!isPaused.value) return;
    isRunning.value = true;
    isPaused.value = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = secondsLeft.value - 1;
      secondsLeft.value = next;
      if (next <= 0) {
        cancelTimer();
        _onTimeout?.call();
      }
    });
  }

  /// Zaman bittiğinde (timer=0) timer'ı durdur
  void stopTimer() {
    cancelTimer();
    secondsLeft.value = 0;
  }

  /// Timer'ı resetliyoruz.
  void resetTimerWithNewSettings() {
    startRoundTimer(seconds: roundSeconds.value, onTimeout: _onTimeout);
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    isRunning.value = false;
  }

  void setRoundSeconds(int s) {
    roundSeconds.value = s;
  }

  @override
  void onClose() {
    cancelTimer();
    super.onClose();
  }
}
