package com.alanciemian.sleeper

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.IBinder
import java.time.LocalDateTime
import android.media.AudioManager
import android.view.KeyEvent
import java.time.Duration
import java.util.*


class SleepState(sleepMin: Int, keepAliveMin: Int) {
    private val sleepDuration: Duration = Duration.ofMinutes(sleepMin.toLong())
    private val keepAliveDuration: Duration = Duration.ofMinutes(keepAliveMin.toLong())
    private var sleepTrigger: LocalDateTime? = null
    private var lastKeepAlive: LocalDateTime? = null


    val sleepTimeRemaining: Duration 
        get() {
        assert(isSleepTimerActive)
        assert(sleepTrigger != null)
        val now = LocalDateTime.now()
        return if ( now.isBefore(sleepTrigger!!) ) Duration.between(now, sleepTrigger!!) else Duration.ofMinutes(0)
        }

    val isSleepTimeElapsed: Boolean
        get() {
            assert(isSleepTimerActive)
            return sleepTrigger?.isBefore(LocalDateTime.now()) ?: true
        }

    val isSleepTimerActive get() = (sleepTrigger != null)

    val isKeepAliveElapsed: Boolean
        get() {
            assert(lastKeepAlive != null)
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


class SleepManager(private val audioManager: AudioManager, var state: SleepState) {

    fun onStart() {
        state.resetKeepAlive()
    }

    fun onTick() {
        var isPlaying: Boolean = audioManager.isMusicActive
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
        audioManager.dispatchMediaKeyEvent(
            KeyEvent(
                KeyEvent.ACTION_DOWN,
                KeyEvent.KEYCODE_MEDIA_PAUSE
            )
        )
        audioManager.dispatchMediaKeyEvent(
            KeyEvent(
                KeyEvent.ACTION_UP,
                KeyEvent.KEYCODE_MEDIA_PAUSE
            )
        )
    }

    private fun motivatePlayer() {
        // Simulating a media key press seems to be enough to keep player happy
        pausePlayer()
    }
}


class SleepTask(
    private var manager: SleepManager,
    private var notificationManager: NotificationManager,
    private var notificationBuilder: Notification.Builder
    ) : TimerTask() {

    override fun run() {
        manager.onTick()
        notificationBuilder.setContentText(buildNotificationContent())
        notificationManager.notify(1, notificationBuilder.build())
    }

    private fun buildNotificationContent(): String {
        return if ( manager.state.isSleepTimerActive ) {
            val sleep = formatDuration(manager.state.sleepTimeRemaining)
            "Sleep time remaining: $sleep"
        } else {
            "Waiting for music to begin..."
        }
    }

    private fun formatDuration(d: Duration): String {
        // Minutes:Seconds
        val minutes = d.toMinutes()
        val seconds = d.toMillis() / 1000 - 60 * minutes
    
        val minutesPadding = if (minutes < 10) "0" else ""
        val secondsPadding = if (seconds < 10) "0" else ""
    
        return "$minutesPadding$minutes:$secondsPadding$seconds"
    }
    
}


class SleepService : Service() {
    private val channelID = "sleeper service channel"
    private val deleteReceiver = DeleteReceiver()

    companion object {
        var timer : Timer? = null

        fun startService(context: Context, sleep: Int, keepAlive: Int) {
            assert( timer == null )
            timer = Timer()
            val startIntent = Intent(context, SleepService::class.java)
            val params = intArrayOf(sleep, keepAlive)
            startIntent.putExtra("params", params)
            context.startForegroundService(startIntent)
        }

        fun stopService(context: Context) {
            if ( timer != null ) {
                timer!!.cancel()
                timer = null
                val stopIntent = Intent(context, SleepService::class.java)
                context.stopService(stopIntent)
            }
    }
    }

    class DeleteReceiver: BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            stopService(context)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationBuilder = createNotificationBuilder()
        startForeground(1, notificationBuilder.build())

        val params = intent!!.getIntArrayExtra("params")!!
        val state = SleepState(params[0], params[1])
        val manager = SleepManager(getSystemService(Context.AUDIO_SERVICE) as AudioManager, state)
        val notificationManager= getSystemService(NotificationManager::class.java) as NotificationManager
        val task = SleepTask(manager, notificationManager, notificationBuilder)
        manager.onStart()
        timer?.schedule(task, 0, 1000)

        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        unregisterReceiver(deleteReceiver)
        super.onDestroy()
    }


    private fun createNotificationChannel() {
        val serviceChannel = NotificationChannel(
            channelID, "Sleeper Service Channel",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager!!.createNotificationChannel(serviceChannel)
    }


    private fun createNotificationBuilder():Notification.Builder {
        createNotificationChannel()
        val contentIntent = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val deleteIntent = PendingIntent.getBroadcast(
            this, 0, Intent("NOTIFICATION_DELETED"), PendingIntent.FLAG_IMMUTABLE)
            registerReceiver(deleteReceiver, IntentFilter("NOTIFICATION_DELETED"))
        return Notification.Builder(this, channelID)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setSmallIcon(R.drawable.ic_snooze)
            //.setContentTitle("Sleeper")
            .setContentText("")
            .setContentIntent(contentIntent)
            .setDeleteIntent(deleteIntent)
            .setShowWhen(false)
            .setOngoing(false)
    }
}



  