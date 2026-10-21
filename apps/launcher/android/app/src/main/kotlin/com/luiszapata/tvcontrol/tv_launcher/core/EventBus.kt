package com.luiszapata.tvcontrol.tv_launcher.core

import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArrayList

/** In-process events from native services to the Flutter UI and the companion server. */
sealed interface LauncherEvent {
    data object AppsChanged : LauncherEvent
    data class LayoutChanged(val layoutJson: String) : LauncherEvent
    data class PairingCode(val code: String?, val client: String?) : LauncherEvent
    data class Clients(val names: List<String>) : LauncherEvent
    data class NowPlayingChanged(val json: String?) : LauncherEvent
    data class ForegroundApp(val packageName: String) : LauncherEvent

    /** Every paired device was forgotten; the companion server closes their sockets. */
    data object DevicesRevoked : LauncherEvent
}

object EventBus {
    private val listeners = CopyOnWriteArrayList<(LauncherEvent) -> Unit>()
    private val main = Handler(Looper.getMainLooper())

    fun subscribe(listener: (LauncherEvent) -> Unit): () -> Unit {
        listeners.add(listener)
        return { listeners.remove(listener) }
    }

    /** Delivers on the main thread. */
    fun post(event: LauncherEvent) {
        main.post { listeners.forEach { it(event) } }
    }
}
