import 'package:shared_preferences/shared_preferences.dart';

class SleepState {
  Duration keepAlivePeriod = const Duration(minutes: 5);
  Duration sleepDuration = const Duration(minutes: 30);

  SleepState.load() {
    SharedPreferences.getInstance().then((prefs) {
      final int? sleepMin = prefs.getInt('sleep_minutes');
      sleepDuration = Duration(minutes: sleepMin ?? sleepDuration.inMinutes);
      final int? aliveMin = prefs.getInt('keep_alive_minutes');
      keepAlivePeriod =
          Duration(minutes: aliveMin ?? keepAlivePeriod.inMinutes);
    });
  }

  void save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('sleep_minutes', sleepDuration.inMinutes);
      prefs.setInt('keep_alive_minutes', keepAlivePeriod.inMinutes);
    });
  }

}