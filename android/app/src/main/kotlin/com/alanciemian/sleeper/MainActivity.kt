package com.alanciemian.sleeper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.annotation.NonNull
import android.util.Log


class MainActivity: FlutterActivity(), MethodCallHandler {
  private val channel = "com.alanciemian.sleeper"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler( this )
  }

  
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "startService" -> {
        val args = call.arguments as List<*>
        val sleep = args[0] as Int
        val keepAlive = args[1] as Int
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
    SleepService.stopService(this)
    SleepService.startService(this, sleep, keepAlive)
    return true
  }

  private fun stopService(): Boolean {
    SleepService.stopService(this)
    return true
  }

}
