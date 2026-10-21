package com.luiszapata.tvcontrol.tv_launcher.core

import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import java.util.Calendar

/** What the home screen shows and how edits change the layout. Pure: unit tested. */
object Home {
    /** Favourites on the home screen; with "Todas las apps" they fill two rows of five. */
    const val MAX_PINNED = 9

    /** Pinned apps that are installed, in order. Without a layout, non-system apps are suggested. */
    fun pinned(apps: List<AppInfo>, layout: Layout): List<AppInfo> {
        if (layout.order.isEmpty()) {
            return apps.filter { !it.isSystem && it.packageName !in layout.hidden }.take(MAX_PINNED)
        }
        val byPackage = apps.associateBy { it.packageName }
        return layout.order.mapNotNull { byPackage[it] }.take(MAX_PINNED)
    }

    /** Everything not hidden, alphabetically. */
    fun visible(apps: List<AppInfo>, layout: Layout): List<AppInfo> =
        apps.filter { it.packageName !in layout.hidden }.sortedBy { it.label.lowercase() }

    fun hidden(apps: List<AppInfo>, layout: Layout): List<AppInfo> = apps.filter { it.packageName in layout.hidden }

    fun isPinned(pkg: String, apps: List<AppInfo>, layout: Layout): Boolean = pinned(apps, layout).any { it.packageName == pkg }

    fun canPin(apps: List<AppInfo>, layout: Layout): Boolean = pinned(apps, layout).size < MAX_PINNED

    /** The first edit turns the suggested apps into the layout. */
    private fun materialized(apps: List<AppInfo>, layout: Layout): Layout =
        if (layout.order.isEmpty()) layout.copy(order = pinned(apps, layout).map { it.packageName }) else layout

    fun pin(pkg: String, apps: List<AppInfo>, layout: Layout): Layout {
        val base = materialized(apps, layout)
        if (pkg in base.order || !canPin(apps, base)) return base
        return base.copy(order = base.order + pkg, hidden = base.hidden - pkg)
    }

    fun unpin(pkg: String, apps: List<AppInfo>, layout: Layout): Layout =
        materialized(apps, layout).let { it.copy(order = it.order - pkg) }

    fun hide(pkg: String, apps: List<AppInfo>, layout: Layout): Layout =
        materialized(apps, layout).let { it.copy(order = it.order - pkg, hidden = (it.hidden + pkg).distinct()) }

    fun unhide(pkg: String, layout: Layout): Layout = layout.copy(hidden = layout.hidden - pkg)

    /** Moves a pinned app one step left (-1) or right (+1) among the installed ones. */
    fun shift(pkg: String, delta: Int, apps: List<AppInfo>, layout: Layout): Layout {
        val base = materialized(apps, layout)
        val order = base.order.toMutableList()
        val from = order.indexOf(pkg)
        val to = from + delta
        if (from < 0 || to !in order.indices) return base
        order.add(to, order.removeAt(from))
        return base.copy(order = order)
    }

    /**
     * "Seguir viendo": the most recently used apps (favourites too), newest
     * first, except those closed with "Cerrar app" since they were last used.
     */
    fun recent(
        lastUsed: Map<String, Long>,
        apps: List<AppInfo>,
        layout: Layout,
        closed: Map<String, Long> = emptyMap(),
        limit: Int = RECENT,
    ): List<AppInfo> {
        // System apps (setup screens, vendor tools) are not something you "keep watching".
        val byPackage = visible(apps, layout).filter { !it.isSystem }.associateBy { it.packageName }
        return lastUsed.entries.filter { (pkg, used) -> (closed[pkg] ?: Long.MIN_VALUE) < used }
            .sortedByDescending { it.value }.mapNotNull { byPackage[it.key] }.take(limit)
    }

    /** Favourites as shown: without those already in "Seguir viendo" (no repeats), last opened first. */
    fun favourites(apps: List<AppInfo>, layout: Layout, lastUsed: Map<String, Long>, closed: Map<String, Long> = emptyMap()): List<AppInfo> {
        val recent = recent(lastUsed, apps, layout, closed).map { it.packageName }.toSet()
        return pinned(apps, layout).filter { it.packageName !in recent }
            .sortedByDescending { lastUsed[it.packageName] ?: Long.MIN_VALUE } // stable sort
    }

    const val RECENT = 5

    /** OK cycles 4 → 8 → 4; ◀ ▶ step and stop at the ends. */
    fun columns(current: Int, delta: Int): Int = when {
        delta == 0 -> if (current >= Layout.MAX_COLUMNS) Layout.MIN_COLUMNS else current + 1
        else -> (current + delta).coerceIn(Layout.MIN_COLUMNS, Layout.MAX_COLUMNS)
    }

    /** Night until 4:59, morning until 11:59, afternoon until 18:59. */
    fun greeting(hour: Int): String = when {
        hour < 5 || hour >= 19 -> "BUENAS NOCHES AMIGUE"
        hour < 12 -> "BUENOS DÍAS AMIGUE"
        else -> "BUENAS TARDES AMIGUE"
    }

    private val days = listOf("Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado")
    private val months = listOf(
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
    )

    fun date(c: Calendar): String =
        "${days[c.get(Calendar.DAY_OF_WEEK) - 1]} ${c.get(Calendar.DAY_OF_MONTH)} de ${months[c.get(Calendar.MONTH)]}"
}
