package com.alanciemian.sleeper

import java.time.LocalDateTime
import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent
import java.time.Duration


class SleepState(sleepMin: Int, keepAliveMin: Int) {
    val sleepDuration: Duration = Duration.ofMinutes(sleepMin.toLong())
    val keepAliveDuration: Duration = Duration.ofMinutes(keepAliveMin.toLong())
    private var sleepTrigger: LocalDateTime? = null
    private var lastKeepAlive: LocalDateTime? = null

  
//   Duration get sleepTimeRemaining {
//       assert(isSleepTimerActive);
//       assert(sleepTrigger != null);
//       final now = DateTime.now();
//       return now.isBefore(sleepTrigger!)
//           ? sleepTrigger!.difference(now)
//           : const Duration();
//     }
  
    val isSleepTimeElapsed: Boolean 
        get() {
            assert(isSleepTimerActive);
            return sleepTrigger?.isBefore(LocalDateTime.now()) ?: true
        }
  
    val isSleepTimerActive get() = (sleepTrigger != null)
  
    val isKeepAliveElapsed: Boolean
        get() {
          assert(lastKeepAlive != null);
          return lastKeepAlive?.plus(keepAliveDuration)?.isBefore(LocalDateTime.now()) ?: true
        }
  
    fun start() {
      sleepTrigger = LocalDateTime.now().plus(sleepDuration)
    }
  
    fun cancel() { 
      sleepTrigger = null
    }
  
    fun resetKeepAlive() {
      lastKeepAlive = LocalDateTime.now()
    }
  }


  class SleepManager(val audioManager: AudioManager, var state: SleepState) {

    fun onStart() {
      state.resetKeepAlive()
    }
  
    fun onTick() {
      var isPlaying: Boolean = audioManager.isMusicActive()
      // If timer has elapsed, pause the audio and clear the sleep timer
      if (state.isSleepTimerActive && state.isSleepTimeElapsed) {
        pausePlayer()
        isPlaying = false
      }
      // Check status of player
      if (isPlaying) {
        // Audio is currently playing
        if (!state.isSleepTimerActive) {
          // Audio has started proper, restart the sleep timer
          state.start()
        }
      } else {
        // Audio is not playing;
        // Reset the sleep timer
        state.cancel()
        // Keep the player motivated if keep alive period has expired
        if (state.isKeepAliveElapsed) {
          motivatePlayer()
          state.resetKeepAlive()
        }
      }
    }
  
    private fun pausePlayer() {
      audioManager.dispatchMediaKeyEvent( KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE) )
      audioManager.dispatchMediaKeyEvent( KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE) )
    }
  
    private fun motivatePlayer() {
      // Simulating a media key press seems to be enough to keep player happy
      pausePlayer()
    }
  
    
  }
  
  