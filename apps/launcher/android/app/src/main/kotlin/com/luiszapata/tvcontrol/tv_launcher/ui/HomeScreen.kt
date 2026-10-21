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

/** Room above a row for the focused card's scale and ring. */
const val RING = 16f

/** Cards per row: always whole, never cut. */
const val VISIBLE = 5

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
        setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, ui.pxf(58f))
    }
    private val date = ui.text("", 15f, 500, C.INK2)
    private val weatherBox = ui.horizontal().apply { visibility = View.GONE }
    private val weatherIcon = ui.icon(Ic.CLOUD, 24f, C.AMBER)
    private val temp = ui.text("", 36f, 200, spacing = -1.4f, tabular = true)
    private val place = ui.text(Weather.PLACE, 13f, 700)
    private val condition = ui.text("", 12f, 500, C.INK3)
    private val favRow = Carousel()
    private val recentTitle = ui.text("Seguir viendo", 15f, 700, spacing = -0.15f)
    private val recentRow = Carousel()
    // Declared before init {}: middle() uses it while the screen is built.
    private val allCount = ui.text("", 12f, 600).apply { setTextColor(ui.onFill(C.INK3, C.INK_ON_FILL)); isDuplicateParentStateEnabled = true }
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
        // Manrope's line box is tall: pull the date up under the digits.
        left.addView(date, lp(WRAP, WRAP).apply { topMargin = -ui.px(6) })
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

    /** "Todas las apps" next to the favourites title: one move up from any card. */
    private fun allAppsButton() = FocusFrame(ui, FocusFrame.Look.FILL, 15f, 0x12FFFFFF).apply {
        focusedScale = 1.05f
        tag = "all"
        contentDescription = "Todas las apps"
        val line = ui.horizontal().apply { setPadding(ui.px(14), 0, ui.px(14), 0); isDuplicateParentStateEnabled = true }
        line.addView(ui.icon(Ic.APPS, 15f).apply { setTextColor(ui.onFill(C.INDIGO_LIGHT)); isDuplicateParentStateEnabled = true })
        line.addView(ui.text("Todas las apps", 13f, 700).apply { setTextColor(ui.onFill(C.INK)); isDuplicateParentStateEnabled = true },
            lp(WRAP, WRAP).apply { marginStart = ui.px(7) })
        line.addView(allCount, lp(WRAP, WRAP).apply { marginStart = ui.px(6) })
        addView(line, flp(WRAP, MATCH))
        setOnClickListener { Overlays.allApps(act) }
    }

    private fun middle(): View {
        val col = ui.vertical().apply {
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
        }
        val titleRow = ui.horizontal().apply { clipChildren = false }
        titleRow.addView(ui.text("Tus favoritos", 15f, 700, spacing = -0.15f), lp(0, WRAP, 1f))
        titleRow.addView(allAppsButton(), lp(WRAP, ui.px(30)))
        col.addView(titleRow, lp(MATCH, WRAP).apply { topMargin = ui.px(14) })
        col.addView(favRow.wrapper, rowLp(14f))
        col.addView(recentTitle, lp(WRAP, WRAP).apply { topMargin = ui.px(6) })
        col.addView(recentRow.wrapper, rowLp(14f))
        return col
    }

    /**
     * Exactly [VISIBLE] whole cards, never a cut one: moving past an edge
     * shifts the window by one card. Arrows in the side margins say there is
     * more that way.
     */
    private inner class Carousel {
        val row: LinearLayout = ui.horizontal().apply { gravity = Gravity.TOP; clipChildren = false }
        private val leftArrow = ui.icon(Ic.CHEVRON_LEFT, 28f, C.INK2)
        private val rightArrow = ui.icon(Ic.CHEVRON_RIGHT, 28f, C.INK2)

        /** Full screen width: the arrows sit in the side margins. */
        val wrapper = FrameLayout(ui.context).apply {
            clipChildren = false
            clipToPadding = false // the top padding is room for the focused card's ring
            setPadding(0, ui.px(RING), 0, 0)
            addView(row, flp(MATCH, WRAP).apply { setMargins(ui.px(SIDE), 0, ui.px(SIDE), 0) })
            addView(leftArrow, flp(ui.px(SIDE), ui.px(40), Gravity.START))
            addView(rightArrow, flp(ui.px(SIDE), ui.px(40), Gravity.END))
        }

        private var cards: List<() -> AppCard> = emptyList()
        private var first = 0

        fun set(items: List<() -> AppCard>, cardHeightDp: Float) {
            cards = items
            first = first.coerceIn(0, maxOf(0, items.size - VISIBLE))
            val top = ui.px(RING + cardHeightDp / 2 - 20)
            (leftArrow.layoutParams as FrameLayout.LayoutParams).topMargin = top
            (rightArrow.layoutParams as FrameLayout.LayoutParams).topMargin = top
            bind(null)
        }

        private fun bind(focus: Int?) {
            row.removeAllViews()
            for (i in first until minOf(first + VISIBLE, cards.size)) {
                val card = cards[i]()
                card.frame.setOnKeyListener { _, code, e ->
                    if (e.action != android.view.KeyEvent.ACTION_DOWN) return@setOnKeyListener false
                    when {
                        code == android.view.KeyEvent.KEYCODE_DPAD_RIGHT && i == first + VISIBLE - 1 && i + 1 < cards.size -> {
                            first++; bind(VISIBLE - 1); true
                        }
                        code == android.view.KeyEvent.KEYCODE_DPAD_LEFT && i == first && first > 0 -> {
                            first--; bind(0); true
                        }
                        else -> false
                    }
                }
                row.addView(card, lp(WRAP, WRAP).apply { if (i > first) marginStart = ui.px(16) })
            }
            leftArrow.visibility = if (first > 0) View.VISIBLE else View.INVISIBLE
            rightArrow.visibility = if (first + VISIBLE < cards.size) View.VISIBLE else View.INVISIBLE
            focus?.let { (row.getChildAt(it) as? AppCard)?.frame?.requestFocus() }
        }

        fun reset() { first = 0 }
    }

    private fun rowLp(top: Float) = lp(MATCH, WRAP).apply { setMargins(-ui.px(SIDE), ui.px(top - RING), -ui.px(SIDE), 0) }

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
        val w = (960f - 2 * SIDE - 16f * (VISIBLE - 1)) / VISIBLE
        val h = w * 9 / 16
        allCount.text = "${Home.visible(act.apps, act.layout).size}"
        favRow.set(Home.favourites(act.apps, act.layout, act.lastUsed).map { app ->
            {
                AppCard(ui, w, app.label, onSelect = { act.launch(app.packageName) },
                    onLongPress = { Overlays.appOptions(act, app) }, art = AppCard.appArt(ui, app, h)).also { it.frame.tag = "app:${app.packageName}" }
            }
        }, h)
        val recent = Home.recent(act.lastUsed, act.apps, act.layout)
        recentRow.set(recent.map { app ->
            {
                AppCard(ui, w, app.label, onSelect = { act.launch(app.packageName) },
                    onLongPress = { Overlays.appOptions(act, app) }, art = AppCard.appArt(ui, app, h)).also { it.frame.tag = "recent:${app.packageName}" }
            }
        }, h)
        recentTitle.visibility = if (recent.isEmpty()) View.GONE else View.VISIBLE
        recentRow.wrapper.visibility = recentTitle.visibility

        inputsButton.visibility = if (act.inputs.any { it.kind == "hdmi" }) View.VISIBLE else View.GONE
        restoreFocus()
    }

    /** Where focus goes back when an overlay closes. */
    fun remember(tag: String?) { if (tag != null) focusKey = tag }

    /** Home pressed: start again from the first favourite. */
    fun focusFirst() {
        focusKey = null
        favRow.reset()
        render()
        first()?.requestFocus()
    }

    fun restoreFocus() {
        (focusKey?.let { view.findViewWithTag<View>(it) } ?: first())?.requestFocus()
    }

    private fun first(): View? = (favRow.row.getChildAt(0) as? AppCard)?.frame
}
