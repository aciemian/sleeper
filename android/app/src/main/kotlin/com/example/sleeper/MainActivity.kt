package com.alanciemian.sleeper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.annotation.NonNull
import android.content.Context
import android.media.AudioManager



class MainActivity: FlutterActivity(), MethodCallHandler {
  private val CHANNEL = "com.alanciemian/sleeper"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler( this )
  }

  
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startService" -> {
        val args = call.arguments as List<Int>
        val sleep = args[0]
        val keepAlive = args[1]
        result.success(startService(sleep, keepAlive))
      }
      "stopService" -> {
        result.success(stopService())
      }
      else -> {
        result.notImplemented()
      }
     }
  }
    
  private fun startService( sleep: Int, keepAlive: Int ): Boolean {
    val state = SleepState( sleep, keepAlive )
    val audioService = getSystemService(Context.AUDIO_SERVICE) as AudioManager

    return true
  }

  private fun stopService(): Boolean {
    return true
  }

}
