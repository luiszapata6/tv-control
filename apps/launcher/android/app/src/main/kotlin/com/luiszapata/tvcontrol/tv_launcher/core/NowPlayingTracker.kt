package com.luiszapata.tvcontrol.tv_launcher.core

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import com.luiszapata.tvcontrol.tv_launcher.companion.NowPlaying

/**
 * Exists so the launcher can be granted notification access, which is what
 * lets it read active media sessions (title, app, play state).
 */
class NowPlayingListenerService : NotificationListenerService()

/** Watches the active media session and publishes changes. */
class NowPlayingTracker(private val context: Context) {
    private val manager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val component = ComponentName(context, NowPlayingListenerService::class.java)
    private val main = Handler(Looper.getMainLooper())
    private var watched: MediaController? = null
    private var last: NowPlaying? = null

    private val callback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = publish()
        override fun onMetadataChanged(metadata: MediaMetadata?) = publish()
        override fun onSessionDestroyed() = refresh()
    }

    private val sessionsListener = MediaSessionManager.OnActiveSessionsChangedListener { refresh() }

    fun start() {
        try {
            manager.addOnActiveSessionsChangedListener(sessionsListener, component, main)
            refresh()
        } catch (e: SecurityException) {
            // Notification access not granted yet: nowPlaying stays null.
        }
    }

    fun stop() {
        try {
            manager.removeOnActiveSessionsChangedListener(sessionsListener)
        } catch (_: Exception) {
        }
        watched?.unregisterCallback(callback)
        watched = null
    }

    fun current(): NowPlaying? = last ?: snapshot(pickController())

    private fun pickController(): MediaController? = try {
        val sessions = manager.getActiveSessions(component)
        sessions.firstOrNull { it.playbackState?.state == PlaybackState.STATE_PLAYING } ?: sessions.firstOrNull()
    } catch (e: SecurityException) {
        null
    }

    private fun refresh() {
        val next = pickController()
        if (next?.sessionToken != watched?.sessionToken) {
            watched?.unregisterCallback(callback)
            watched = next
            next?.registerCallback(callback, main)
        }
        publish()
    }

    private fun publish() {
        val now = snapshot(watched)
        if (now == last) return
        last = now
        EventBus.post(LauncherEvent.NowPlayingChanged(now?.toJson()?.toString()))
    }

    private fun snapshot(c: MediaController?): NowPlaying? {
        if (c == null) return null
        val meta = c.metadata
        val state = c.playbackState
        val title = meta?.getString(MediaMetadata.METADATA_KEY_TITLE)
            ?: meta?.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
            ?: return null
        val subtitle = meta.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: meta.getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)
        val duration = meta.getLong(MediaMetadata.METADATA_KEY_DURATION).takeIf { it > 0 }
        return NowPlaying(
            packageName = c.packageName,
            title = title,
            subtitle = subtitle,
            state = when (state?.state) {
                PlaybackState.STATE_PLAYING -> "playing"
                PlaybackState.STATE_PAUSED -> "paused"
                PlaybackState.STATE_BUFFERING, PlaybackState.STATE_CONNECTING -> "buffering"
                else -> "stopped"
            },
            positionMs = state?.position?.takeIf { it >= 0 },
            durationMs = duration,
        )
    }
}
