import 'package:shared_preferences/shared_preferences.dart';

class SleepState {
  DateTime? sleepTrigger;
  Duration keepAlivePeriod = const Duration(minutes: 5);
  DateTime lastKeepAlive = DateTime.now();
  Duration sleepDuration = const Duration(minutes: 1);

  SleepState.load() {
    SharedPreferences.getInstance().then((prefs) {
      final int? sleepMin = prefs.getInt('sleep_minutes');
      sleepDuration = Duration(minutes: sleepMin ?? sleepDuration.inMinutes);
      final int? aliveMin = prefs.getInt('keep_alive_minutes');
      keepAlivePeriod =
          Duration(minutes: aliveMin ?? keepAlivePeriod.inMinutes);
      final String? trigger = prefs.getString('sleep_trigger');
      if (trigger != null) sleepTrigger = DateTime.tryParse(trigger);
      final String? alive = prefs.getString('keep_alive');
      if (alive != null) lastKeepAlive = DateTime.parse(alive);
    });
  }

  void save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('sleep_minutes', sleepDuration.inMinutes);
      prefs.setInt('keep_alive_minutes', keepAlivePeriod.inMinutes);
      if ( isSleepTimerActive ) {
        prefs.setString('sleep_trigger', sleepTrigger!.toIso8601String());
      } else {
        prefs.remove('sleep_trigger');
      }
      prefs.setString('keep_alive', lastKeepAlive.toIso8601String());
    });
  }


Duration get sleepTimeRemaining {
    assert(isSleepTimerActive);
    assert(sleepTrigger != null);
    final now = DateTime.now();
    return now.isBefore(sleepTrigger!)
        ? sleepTrigger!.difference(now)
        : const Duration();
  }

  bool get isSleepTimeElapsed {
    assert(isSleepTimerActive);
    assert(sleepTrigger != null);
    return sleepTrigger!.isBefore(DateTime.now());
  }

  bool get isSleepTimerActive {
    return (sleepTrigger != null);
  }

  bool get isKeepAliveElapsed {
    return lastKeepAlive.add(keepAlivePeriod).isBefore(DateTime.now());
  }

  void start() {
    sleepTrigger = DateTime.now().add(sleepDuration);
  }

  void cancel() {
    sleepTrigger = null;
  }

  void resetKeepAlive() {
    lastKeepAlive = DateTime.now();
  }
}
