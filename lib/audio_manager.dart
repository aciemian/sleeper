// ignore_for_file: avoid_print

import 'package:flutter/services.dart';


class AndroidAudioManager {
  static const int keyPause = 127;
  static const int keyPlay = 126;
  static const int keyPlayPause = 85;
  static const int keyStop = 86;

  static const platform = MethodChannel('com.alanciemian/sleeper');

  static Future<bool> isAudioPlaying() async {
    try {
      final bool result = await platform.invokeMethod('isAudioPlaying');
      return Future.value(result);
    } on PlatformException {
      return Future.value(false);
    }
  }

  static Future<void> simulateMediaKey( int code ) async {
    try {
      await platform.invokeMethod('simulateMediaKey', code);
    } on PlatformException {
      print('simulateMediaKey failed.');
    }
  }

  static Future<void> muteVolume( bool mute ) async {
    try {
      await platform.invokeMethod('muteVolume', mute );
    } on PlatformException {
      print('muteValue ($mute) failed.');
    }
  }
  
}
