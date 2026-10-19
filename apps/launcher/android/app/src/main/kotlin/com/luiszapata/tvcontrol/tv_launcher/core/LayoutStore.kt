package com.luiszapata.tvcontrol.tv_launcher.core

import android.content.Context
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import org.json.JSONObject

/** The launcher layout, the single source of truth for the UI and the iPhone. */
class LayoutStore(context: Context) {
    private val prefs = context.getSharedPreferences("launcher", Context.MODE_PRIVATE)

    @Synchronized
    fun get(): Layout = prefs.getString(KEY, null)?.let { Layout.fromJson(JSONObject(it)) } ?: Layout()

    @Synchronized
    fun set(layout: Layout): Layout {
        val normalized = layout.normalized()
        prefs.edit().putString(KEY, normalized.toJson().toString()).apply()
        EventBus.post(LauncherEvent.LayoutChanged(normalized.toJson().toString()))
        return normalized
    }

    private companion object {
        const val KEY = "layout"
    }
}
