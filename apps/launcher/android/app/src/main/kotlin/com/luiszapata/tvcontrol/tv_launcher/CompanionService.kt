package com.luiszapata.tvcontrol.tv_launcher

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import com.luiszapata.tvcontrol.tv_launcher.companion.CompanionHandler
import com.luiszapata.tvcontrol.tv_launcher.companion.CompanionServer
import com.luiszapata.tvcontrol.tv_launcher.companion.NsdAdvertiser
import com.luiszapata.tvcontrol.tv_launcher.companion.Protocol
import com.luiszapata.tvcontrol.tv_launcher.core.EventBus
import com.luiszapata.tvcontrol.tv_launcher.core.Launcher
import com.luiszapata.tvcontrol.tv_launcher.core.LauncherEvent
import org.json.JSONObject

/**
 * Keeps the companion WebSocket server running while other apps are on
 * screen (the launcher activity is stopped then).
 */
class CompanionService : Service() {
    private var server: CompanionServer? = null
    private var nsd: NsdAdvertiser? = null
    private var unsubscribe: (() -> Unit)? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Launcher.init(this)
        startForegroundCompat()
        val s = CompanionServer(
            Protocol.PORT,
            handlerFactory = {
                CompanionHandler(
                    backend = Launcher,
                    pairing = Launcher.pairing,
                    onForegroundApp = { EventBus.post(LauncherEvent.ForegroundApp(it)) },
                )
            },
            onClientsChanged = { EventBus.post(LauncherEvent.Clients(it)) },
        )
        server = s
        try {
            s.start()
        } catch (e: Exception) {
            stopSelf()
            return
        }
        nsd = NsdAdvertiser(this).also { it.start(Launcher.tvName, Protocol.PORT, Launcher.deviceId) }
        unsubscribe = EventBus.subscribe { event ->
            when (event) {
                is LauncherEvent.LayoutChanged ->
                    s.broadcastEvent(Protocol.Event.LAYOUT_CHANGED, JSONObject().put("layout", JSONObject(event.layoutJson)))
                is LauncherEvent.NowPlayingChanged ->
                    s.broadcastEvent(
                        Protocol.Event.NOW_PLAYING,
                        JSONObject().put("nowPlaying", event.json?.let { JSONObject(it) } ?: JSONObject.NULL),
                    )
                is LauncherEvent.ForegroundApp ->
                    s.broadcastEvent(Protocol.Event.FOREGROUND_APP, JSONObject().put("package", event.packageName))
                LauncherEvent.AppsChanged -> s.broadcastEvent(Protocol.Event.APPS_CHANGED, JSONObject())
                else -> Unit
            }
        }
        running = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        running = false
        unsubscribe?.invoke()
        nsd?.stop()
        try {
            server?.stop(500)
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    private fun startForegroundCompat() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, "Control desde el iPhone", NotificationManager.IMPORTANCE_MIN),
        )
        val notification = Notification.Builder(this, CHANNEL)
            .setContentTitle("TV Control")
            .setContentText("Listo para el iPhone")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(ID, notification)
        }
    }

    companion object {
        private const val CHANNEL = "companion"
        private const val ID = 7790

        @Volatile
        var running = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, CompanionService::class.java)
            try {
                context.startForegroundService(intent)
            } catch (_: Exception) {
                // Background start limits: MainActivity starts it again when shown.
            }
        }
    }
}
