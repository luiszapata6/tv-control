package com.luiszapata.tvcontrol.tv_launcher

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
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
    private val main = Handler(Looper.getMainLooper())
    private var server: CompanionServer? = null
    private var nsd: NsdAdvertiser? = null
    private var unsubscribe: (() -> Unit)? = null
    private var failures = 0
    private val retry = Runnable { startServer() }
    private val sweep = object : Runnable {
        override fun run() {
            server?.sweep()
            main.postDelayed(this, SWEEP_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Launcher.init(this)
        startForegroundCompat()
        nsd = NsdAdvertiser(this)
        unsubscribe = EventBus.subscribe { event ->
            val s = server ?: return@subscribe
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
                LauncherEvent.DevicesRevoked -> s.closeAuthenticated()
                else -> Unit
            }
        }
        startServer()
        main.postDelayed(sweep, SWEEP_MS)
    }

    /** Also called when MainActivity resumes: restarts a server that failed. */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (server == null) {
            main.removeCallbacks(retry)
            failures = 0
            startServer()
        }
        return START_STICKY
    }

    private fun startServer() {
        if (server != null) return
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
            onStarted = { started -> main.post { onServerStarted(started) } },
            onFailed = { failedServer, e -> main.post { onServerFailed(failedServer, e) } },
            onSweep = { if (Launcher.pairing.expireIfStale()) Launcher.showPairingCode(null, null) },
        )
        server = s
        try {
            s.start()
        } catch (e: Exception) {
            onServerFailed(s, e)
        }
    }

    private fun onServerStarted(s: CompanionServer) {
        if (server !== s) return
        failures = 0
        running = true
        Log.i(TAG, "companion server listening on ${Protocol.PORT}")
        nsd?.start(Launcher.tvName, Protocol.PORT, Launcher.deviceId)
    }

    private fun onServerFailed(s: CompanionServer, e: Exception) {
        if (server !== s) return
        Log.e(TAG, "companion server failed", e)
        running = false
        server = null
        nsd?.stop()
        try {
            s.stop(0)
        } catch (_: Exception) {
        }
        failures++
        if (failures >= MAX_RETRIES) {
            // MainActivity.onResume starts the service again.
            stopSelf()
        } else {
            main.postDelayed(retry, RETRY_DELAY_MS * failures)
        }
    }

    override fun onDestroy() {
        running = false
        main.removeCallbacks(retry)
        main.removeCallbacks(sweep)
        unsubscribe?.invoke()
        nsd?.stop()
        val s = server
        server = null
        try {
            s?.stop(500)
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
        private const val TAG = "CompanionService"
        private const val SWEEP_MS = 5_000L
        private const val RETRY_DELAY_MS = 5_000L
        private const val MAX_RETRIES = 5

        /** True only while the server is bound and listening (set from its onStart). */
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
