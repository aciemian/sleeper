import 'package:flutter/services.dart';

import 'sleep_state.dart';


class SleepService {

  static const platform = MethodChannel('com.alanciemian.sleeper');

  static Future<bool> start( SleepState state ) async {
    try {
      var arguments = [state.sleepDuration.inMinutes, state.keepAlivePeriod.inMinutes];
      final bool result = await platform.invokeMethod('startService', arguments);
      return Future.value(result);
    } on PlatformException {
      return Future.value(false);
    }
  }

  static Future<bool> stop() async {
    try {
      final bool result = await platform.invokeMethod('stopService');
      return Future.value(result);
    } on PlatformException {
      return Future.value(false);
    }
  }
  
}
