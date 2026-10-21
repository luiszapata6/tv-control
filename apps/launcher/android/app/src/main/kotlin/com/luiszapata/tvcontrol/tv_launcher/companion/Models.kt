package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONArray
import org.json.JSONObject

data class AppInfo(val packageName: String, val label: String, val versionCode: Long, val isSystem: Boolean) {
    fun toJson(): JSONObject = JSONObject()
        .put("package", packageName)
        .put("label", label)
        .put("versionCode", versionCode)
        .put("isSystem", isSystem)
}

data class Layout(val order: List<String> = emptyList(), val hidden: List<String> = emptyList(), val columns: Int = 6) {
    fun toJson(): JSONObject = JSONObject()
        .put("order", JSONArray(order))
        .put("hidden", JSONArray(hidden))
        .put("columns", columns)

    /** Drops duplicates and clamps columns; keeps unknown packages (apps may be reinstalled). */
    fun normalized(): Layout = Layout(
        order = order.distinct(),
        hidden = hidden.distinct().filter { it !in order },
        columns = columns.coerceIn(MIN_COLUMNS, MAX_COLUMNS),
    )

    companion object {
        const val MIN_COLUMNS = 4
        const val MAX_COLUMNS = 8

        fun fromJson(j: JSONObject?): Layout {
            if (j == null) return Layout()
            return Layout(
                order = j.optJSONArray("order").strings(),
                hidden = j.optJSONArray("hidden").strings(),
                columns = j.optInt("columns", 6),
            ).normalized()
        }
    }
}

data class InputInfo(val id: String, val label: String, val kind: String) {
    fun toJson(): JSONObject = JSONObject().put("id", id).put("label", label).put("kind", kind)
}

data class NowPlaying(
    val packageName: String,
    val title: String,
    val subtitle: String?,
    val state: String,
    val positionMs: Long?,
    val durationMs: Long?,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("package", packageName)
        put("title", title)
        if (subtitle != null) put("subtitle", subtitle)
        put("state", state)
        if (positionMs != null) put("positionMs", positionMs)
        if (durationMs != null) put("durationMs", durationMs)
    }
}

data class UsageEntry(val packageName: String, val label: String, val foregroundMs: Long) {
    fun toJson(): JSONObject = JSONObject().put("package", packageName).put("label", label).put("foregroundMs", foregroundMs)
}

fun JSONArray?.strings(): List<String> {
    if (this == null) return emptyList()
    return (0 until length()).mapNotNull { optString(it, null) }
}

/** Scales (w, h) down so that max(w, h) <= maxSide, keeping the aspect ratio; never scales up. */
fun fitIconSize(w0: Int, h0: Int, maxSide: Int = Protocol.MAX_ICON_PX): Pair<Int, Int> {
    val w = w0.coerceAtLeast(1)
    val h = h0.coerceAtLeast(1)
    val longest = maxOf(w, h)
    if (longest <= maxSide) return w to h
    // Integer math so the longest side is exactly maxSide.
    return (w.toLong() * maxSide / longest).toInt().coerceAtLeast(1) to
        (h.toLong() * maxSide / longest).toInt().coerceAtLeast(1)
}
