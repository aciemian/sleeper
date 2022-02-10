package com.example.sleeper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.annotation.NonNull
import android.content.Context
import android.media.AudioManager
import android.view.KeyEvent


class MainActivity: FlutterActivity(), MethodCallHandler {
  private val CHANNEL = "com.alanciemian/sleeper"
  private var audioManager: AudioManager? =  null

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler( this )
    audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if ( call.method == "isAudioPlaying" ) {
      val isPlaying = isAudioPlaying()
      result.success(isPlaying)
    } else if ( call.method == "muteVolume" ) {
      muteVolume( call.arguments as Boolean )
      result.success( null )
    } else if ( call.method == "simulateMediaKey" ) {
      simulateMediaKey( call.arguments as Int )
      result.success( null )
    } else {
      result.notImplemented()
    }
  }
    
  private fun isAudioPlaying(): Boolean {
    return audioManager!!.isMusicActive()
  }

  private fun muteVolume( mute: Boolean ) {
    audioManager!!.adjustVolume( if (mute) AudioManager.ADJUST_MUTE else AudioManager.ADJUST_UNMUTE, AudioManager.FLAG_REMOVE_SOUND_AND_VIBRATE )
  }

  private fun simulateMediaKey( keyCode: Int ) {
    audioManager!!.dispatchMediaKeyEvent( KeyEvent(KeyEvent.ACTION_DOWN, keyCode) )
    audioManager!!.dispatchMediaKeyEvent( KeyEvent(KeyEvent.ACTION_UP, keyCode) )
  }
}
