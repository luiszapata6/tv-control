package com.luiszapata.tvcontrol.tv_launcher.core

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import com.luiszapata.tvcontrol.tv_launcher.companion.UsageEntry

/** Foreground time per app. Needs PACKAGE_USAGE_STATS (granted by tools/install). */
class UsageRepository(private val context: Context, private val labelFor: (String) -> String) {
    fun hasAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        @Suppress("DEPRECATION")
        val mode = ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun usage(days: Int): Pair<Long, List<UsageEntry>>? {
        if (!hasAccess()) return null
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - days * 24L * 60 * 60 * 1000
        val totals = usm.queryAndAggregateUsageStats(start, end)
            .filter { (pkg, s) -> s.totalTimeInForeground > 60_000 && pkg != context.packageName }
            .map { (pkg, s) -> UsageEntry(pkg, labelFor(pkg), s.totalTimeInForeground) }
            .sortedByDescending { it.foregroundMs }
            .take(30)
        return start to totals
    }

    /** When each app was last in front over the past [days] (empty without access). */
    fun lastUsed(days: Int = 7): Map<String, Long> {
        if (!hasAccess()) return emptyMap()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        return usm.queryAndAggregateUsageStats(end - days * 24L * 60 * 60 * 1000, end)
            .filter { (pkg, s) -> s.totalTimeInForeground > 0 && pkg != context.packageName }
            .mapValues { it.value.lastTimeUsed }
    }
}
