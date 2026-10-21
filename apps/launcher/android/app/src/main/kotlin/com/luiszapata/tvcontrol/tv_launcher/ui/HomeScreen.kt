package com.luiszapata.tvcontrol.tv_launcher.ui

import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextClock
import android.widget.TextView
import com.luiszapata.tvcontrol.tv_launcher.MainActivity
import com.luiszapata.tvcontrol.tv_launcher.core.Home
import com.luiszapata.tvcontrol.tv_launcher.core.Weather
import java.util.Calendar

/** Horizontal safe margin (dp). */
const val SIDE = 80f

/** Clock, weather, favourites (+ "Todas las apps"), HDMI inputs and the iPhone status. */
class HomeScreen(private val act: MainActivity) {
    private val ui = act.ui
    val view = FrameLayout(ui.context)

    private val greeting = ui.text("", 12f, 700, C.AMBER, spacing = 2.6f)
    private val clock = TextClock(ui.context).apply {
        format24Hour = "H:mm"
        format12Hour = "H:mm"
        typeface = ui.font(200)
        setTextColor(C.INK)
        includeFontPadding = false
        letterSpacing = -0.045f
        fontFeatureSettings = "tnum"
        setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, ui.pxf(72f))
    }
    private val date = ui.text("", 15f, 500, C.INK2)
    private val weatherBox = ui.horizontal().apply { visibility = View.GONE }
    private val weatherIcon = ui.icon(Ic.CLOUD, 24f, C.AMBER)
    private val temp = ui.text("", 36f, 200, spacing = -1.4f, tabular = true)
    private val place = ui.text(Weather.PLACE, 13f, 700)
    private val condition = ui.text("", 12f, 500, C.INK3)
    private val favRow = cardRow()
    private val recentTitle = ui.text("Seguir viendo", 15f, 700, spacing = -0.15f)
    private val recentRow = cardRow()
    private lateinit var inputsButton: View
    private val footerIcon = ui.icon(Ic.PHONE, 15f, C.INK4)
    private val footerName = ui.text("Sin iPhone conectado", 12f, 600, C.INK4)
    private val footerPill = ui.horizontal()

    /** Tag of the last focused element, to put focus back after a rebuild. */
    private var focusKey: String? = null
    private var rendered = false

    init {
        view.clipChildren = false
        // Fixed deep-blue glow, top right; drawn once by the GPU.
        view.addView(View(ui.context).apply {
            background = GradientDrawable().apply {
                gradientType = GradientDrawable.RADIAL_GRADIENT
                colors = intArrayOf(0x52123A8C, 0x00123A8C)
                setGradientCenter(0.8f, 0f)
                gradientRadius = ui.pxf(640f)
            }
        }, flp(MATCH, MATCH))

        val content = ui.vertical().apply {
            clipChildren = false
            clipToPadding = false
            // TVs crop the edges (overscan): keep everything inside a ~8% safe area.
            setPadding(ui.px(SIDE), ui.px(32), ui.px(SIDE), ui.px(22))
        }
        content.addView(header(), lp(MATCH, WRAP))
        content.addView(middle(), lp(MATCH, 0, 1f))
        content.addView(footer(), lp(MATCH, ui.px(22)))
        view.addView(content, flp(MATCH, MATCH))
    }

    private fun header(): View {
        val row = ui.horizontal().apply { gravity = Gravity.TOP; clipChildren = false }
        val left = ui.vertical()
        left.addView(greeting, lp(WRAP, WRAP))
        left.addView(clock, lp(WRAP, WRAP).apply { topMargin = ui.px(5); marginStart = -ui.px(4) })
        left.addView(date, lp(WRAP, WRAP).apply { topMargin = ui.px(5) })
        row.addView(left)
        row.addView(View(ui.context), lp(0, 1, 1f))

        weatherBox.addView(weatherIcon)
        weatherBox.addView(temp, lp(WRAP, WRAP).apply { marginStart = ui.px(11) })
        weatherBox.addView(View(ui.context).apply { setBackgroundColor(0x1AFFFFFF) }, lp(ui.px(1), ui.px(34)).apply { marginStart = ui.px(11) })
        val placeCol = ui.vertical().apply {
            addView(place, lp(WRAP, WRAP))
            addView(condition, lp(WRAP, WRAP).apply { topMargin = ui.px(2) })
        }
        weatherBox.addView(placeCol, lp(WRAP, WRAP).apply { marginStart = ui.px(11) })
        val right = ui.horizontal().apply { clipChildren = false }
        right.addView(weatherBox, lp(WRAP, WRAP).apply { marginEnd = ui.px(20) })
        inputsButton = roundButton(Ic.HDMI, "Entradas", "inputs") { Overlays.inputs(act) }
        right.addView(inputsButton, lp(ui.px(44), ui.px(44)).apply { setMargins(-ui.px(3), -ui.px(3), ui.px(7), -ui.px(3)) })
        val settings = FocusFrame(ui, FocusFrame.Look.FILL, 19f, 0x12FFFFFF).apply {
            focusedScale = 1.08f
            tag = "settings"
            contentDescription = "Ajustes"
            addView(ui.icon(Ic.TUNE, 17f).apply {
                setTextColor(ui.onFill(C.INK_SOFT))
                isDuplicateParentStateEnabled = true
            }, flp(MATCH, MATCH))
            setOnClickListener { Overlays.settings(act) }
        }
        right.addView(settings, lp(ui.px(44), ui.px(44)).apply { setMargins(-ui.px(3), -ui.px(3), -ui.px(3), -ui.px(3)) })
        row.addView(right, lp(WRAP, WRAP).apply { topMargin = ui.px(2) })
        return row
    }

    private fun roundButton(icon: Int, label: String, key: String, onSelect: () -> Unit) =
        FocusFrame(ui, FocusFrame.Look.FILL, 19f, 0x12FFFFFF).apply {
            focusedScale = 1.08f
            tag = key
            contentDescription = label
            addView(ui.icon(icon, 17f).apply {
                setTextColor(ui.onFill(C.INK_SOFT))
                isDuplicateParentStateEnabled = true
            }, flp(MATCH, MATCH))
            setOnClickListener { onSelect() }
        }

    private fun middle(): View {
        val col = ui.vertical().apply {
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
        }
        col.addView(ui.text("Tus apps", 15f, 700, spacing = -0.15f), lp(WRAP, WRAP))
        col.addView(favRow.first, rowLp(14f))
        col.addView(recentTitle, lp(WRAP, WRAP).apply { topMargin = ui.px(6) })
        col.addView(recentRow.first, rowLp(14f))
        return col
    }

    /**
     * One horizontally scrolling row of cards (like the stock launcher). It
     * spans the full screen width so a focused card's ring is never clipped;
     * padding keeps the cards inside the safe area.
     */
    private fun cardRow(): Pair<android.widget.HorizontalScrollView, LinearLayout> {
        val row = ui.horizontal().apply { gravity = Gravity.TOP; clipChildren = false }
        val scroll = android.widget.HorizontalScrollView(ui.context).apply {
            isHorizontalScrollBarEnabled = false
            clipChildren = false
            clipToPadding = false
            overScrollMode = View.OVER_SCROLL_NEVER
            setPadding(ui.px(SIDE), ui.px(12), ui.px(SIDE), 0)
            addView(row)
        }
        return scroll to row
    }

    private fun rowLp(top: Float) = lp(MATCH, WRAP).apply { setMargins(-ui.px(SIDE), ui.px(top - 12), -ui.px(SIDE), 0) }

    private fun footer(): View {
        val row = ui.horizontal()
        row.addView(footerIcon)
        row.addView(footerName, lp(WRAP, WRAP).apply { marginStart = ui.px(8) })
        footerPill.apply {
            background = ui.rounded(0x1F4ADE80, 10f)
            setPadding(ui.px(7), 0, ui.px(8), 0)
            addView(View(ui.context).apply { background = ui.rounded(C.GREEN, 2.5f) }, lp(ui.px(5), ui.px(5)))
            addView(ui.text("Conectado", 12f, 700, C.GREEN), lp(WRAP, WRAP).apply { marginStart = ui.px(5) })
            visibility = View.GONE
        }
        row.addView(footerPill, lp(WRAP, ui.px(20)).apply { marginStart = ui.px(8) })
        row.addView(View(ui.context), lp(0, 1, 1f))
        row.addView(Overlays.hints(ui, "OK" to "Abrir", "Mantén|OK" to "Opciones"))
        return row
    }

    // ---------------------------------------------------------------- updates

    fun tick() {
        val now = Calendar.getInstance()
        greeting.text = Home.greeting(now.get(Calendar.HOUR_OF_DAY))
        date.text = Home.date(now)
    }

    fun setWeather(w: Weather) {
        weatherIcon.text = String(Character.toChars(Ic.weather(w.code, w.isDay)))
        temp.text = w.temperatureLabel
        condition.text = w.label
        weatherBox.visibility = View.VISIBLE
    }

    fun renderFooter() {
        val connected = act.clients.isNotEmpty()
        footerName.text = if (connected) act.clients.joinToString(", ") else "Sin iPhone conectado"
        footerName.setTextColor(if (connected) C.INK2 else C.INK4)
        footerIcon.setTextColor(if (connected) C.INK2 else C.INK4)
        footerPill.visibility = if (connected) View.VISIBLE else View.GONE
    }

    /** Rebuilds the rows and inputs, keeping focus where it was. */
    fun render() {
        if (!act.loaded) return
        // Before the first render the framework may have focused anything (e.g. Ajustes).
        if (rendered) (act.currentFocus?.tag as? String)?.let { focusKey = it }
        rendered = true
        val cols = act.layout.columns
        val w = (960f - 2 * SIDE - 16f * (cols - 1)) / cols
        favRow.second.removeAllViews()
        val favs = Home.pinned(act.apps, act.layout).map { app ->
            AppCard(ui, w, app.label, onSelect = { act.launch(app.packageName) },
                onLongPress = { Overlays.appOptions(act, app) }, art = AppCard.appArt(ui, app, w * 9 / 16)).also {
                it.frame.tag = "app:${app.packageName}"
            }
        } + AppCard(ui, w, "Todas las apps", onSelect = { Overlays.allApps(act) },
            art = AppCard.allAppsArt(ui, Home.visible(act.apps, act.layout).size)).also { it.frame.tag = "all" }
        favs.forEachIndexed { i, card -> favRow.second.addView(card, lp(WRAP, WRAP).apply { if (i > 0) marginStart = ui.px(16) }) }

        // Smaller cards: seven fit across.
        val rw = (960f - 2 * SIDE - 16f * (Home.RECENT - 1)) / Home.RECENT
        recentRow.second.removeAllViews()
        val recent = Home.recent(act.lastUsed, act.apps, act.layout)
        recent.forEachIndexed { i, app ->
            val card = AppCard(ui, rw, app.label, onSelect = { act.launch(app.packageName) },
                onLongPress = { Overlays.appOptions(act, app) }, art = AppCard.appArt(ui, app, rw * 9 / 16))
            card.frame.tag = "recent:${app.packageName}"
            recentRow.second.addView(card, lp(WRAP, WRAP).apply { if (i > 0) marginStart = ui.px(16) })
        }
        recentTitle.visibility = if (recent.isEmpty()) View.GONE else View.VISIBLE
        recentRow.first.visibility = recentTitle.visibility

        inputsButton.visibility = if (act.inputs.any { it.kind == "hdmi" }) View.VISIBLE else View.GONE
        restoreFocus()
    }

    fun restoreFocus() {
        (focusKey?.let { view.findViewWithTag<View>(it) } ?: first())?.requestFocus()
    }

    private fun first(): View? = (favRow.second.getChildAt(0) as? AppCard)?.frame
}
