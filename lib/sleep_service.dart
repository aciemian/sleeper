import 'package:flutter/services.dart';


class SleepService {

  static const platform = MethodChannel('com.alanciemian/sleeper');

  static Future<bool> start( Duration sleepDuration, Duration keepAliveDuration ) async {
    try {
      var arguments = [sleepDuration.inMinutes, keepAliveDuration.inMinutes];
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
