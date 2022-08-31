import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SleepState {
  Duration keepAlivePeriod = const Duration(minutes: 5);
  Duration sleepDuration = const Duration(minutes: 30);

  StreamController<SleepState> states = StreamController<SleepState>();

  SleepState();

  SleepState.load() {
    load();
  }

  void load() {
    SharedPreferences.getInstance().then((prefs) {
      final int? sleepMin = prefs.getInt('sleep_minutes');
      sleepDuration = Duration(minutes: sleepMin ?? sleepDuration.inMinutes);
      final int? aliveMin = prefs.getInt('keep_alive_minutes');
      keepAlivePeriod = Duration(minutes: aliveMin ?? keepAlivePeriod.inMinutes);
      states.add(this);
    });
  }

  void save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('sleep_minutes', sleepDuration.inMinutes);
      prefs.setInt('keep_alive_minutes', keepAlivePeriod.inMinutes);
      states.add(this);
    });
  }
}
