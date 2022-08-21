import 'package:sleeper/sleep_state.dart';

import 'audio_manager.dart';


class SleepManager {

  static Future<void> onStart(SleepState state) async {
    // resetKeepAlive();
  }

  static Future<void> onTick(SleepState state) async {
    bool isPlaying = await AndroidAudioManager.isAudioPlaying();
    // If timer has elapsed, pause the audio and clear the sleep timer
    if (state.isSleepTimerActive && state.isSleepTimeElapsed) {
      pausePlayer();
      isPlaying = false;
    }
    // Check status of player
    if (isPlaying) {
      // Audio is currently playing
      if (!state.isSleepTimerActive) {
        // Audio has started proper, restart the sleep timer
        state.start();
      }
    } else {
      // Audio is not playing;
      // Reset the sleep timer
      state.cancel();
      // Keep the player motivated if keep alive period has expired
      if (state.isKeepAliveElapsed) {
        motivatePlayer();
        state.resetKeepAlive();
      }
    }
  }

  static Future<void> pausePlayer() async {
    await AndroidAudioManager.simulateMediaKey(AndroidAudioManager.keyPause);
  }

  static Future<void> motivatePlayer() async {
    // Simulating a media key press seems to be enough to keep player happy
    await AndroidAudioManager.simulateMediaKey(AndroidAudioManager.keyPause);
  }

  
}
