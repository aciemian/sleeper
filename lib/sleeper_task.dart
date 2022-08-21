import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class SleeperTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send('onStart');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send('onEvent');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _sendPort?.send('onDestroy');
}

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
    // print('onButtonPressed >> $id');
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.

    //FlutterForegroundTask.launchApp();
    //_sendPort?.send('onNotificationPressed');
  }
}
