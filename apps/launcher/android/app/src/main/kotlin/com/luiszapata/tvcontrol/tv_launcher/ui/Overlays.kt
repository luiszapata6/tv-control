package com.luiszapata.tvcontrol.tv_launcher.ui

import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.luiszapata.tvcontrol.tv_launcher.MainActivity
import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import com.luiszapata.tvcontrol.tv_launcher.core.Home

/** Options sheet, settings panel, all apps, pairing code and key hints. */
object Overlays {
    /** "OK" to "Abrir", or "Mantén|OK" to "Opciones" (text before the key). */
    fun hints(ui: Ui, vararg items: Pair<String, String>): View {
        val row = ui.horizontal()
        items.forEachIndexed { i, (key, action) ->
            val (before, cap) = key.split('|').let { if (it.size == 2) it[0] to it[1] else null to it[0] }
            val item = ui.horizontal()
            if (before != null) item.addView(ui.text(before, 12f, 600, C.INK3), lp(WRAP, WRAP).apply { marginEnd = ui.px(5) })
            item.addView(ui.text(cap, 10f, 800, C.INK_SOFT).apply {
                gravity = Gravity.CENTER
                minWidth = ui.px(19)
                setPadding(ui.px(5), 0, ui.px(5), 0)
                background = ui.rounded(0x14FFFFFF, 4f)
            }, lp(WRAP, ui.px(19)))
            item.addView(ui.text(action, 12f, 600, C.INK3), lp(WRAP, WRAP).apply { marginStart = ui.px(5) })
            row.addView(item, lp(WRAP, WRAP).apply { if (i > 0) marginStart = ui.px(16) })
        }
        return row
    }

    /** A row/button that inverts on focus: icon + title (+ subtitle) + optional trailing view. */
    private fun row(ui: Ui, icon: Int?, title: String, sub: String? = null, heightDp: Float, onSelect: () -> Unit): Pair<FocusFrame, TextView?> {
        val f = FocusFrame(ui, FocusFrame.Look.FILL, 10f).apply {
            focusedScale = 1.02f
            contentDescription = title
            setOnClickListener { onSelect() }
        }
        val line = ui.horizontal().apply {
            setPadding(ui.px(16), 0, ui.px(14), 0)
            isDuplicateParentStateEnabled = true
        }
        if (icon != null) {
            line.addView(ui.icon(icon, 18f).apply { setTextColor(ui.onFill(C.INK2)); isDuplicateParentStateEnabled = true },
                lp(WRAP, WRAP).apply { marginEnd = ui.px(12) })
        }
        val texts = ui.vertical().apply { isDuplicateParentStateEnabled = true }
        texts.addView(ui.text(title, 15f, 700).apply { setTextColor(ui.onFill(C.INK)); isDuplicateParentStateEnabled = true }, lp(MATCH, WRAP))
        val subView = sub?.let {
            ui.text(it, 12f, 600).apply { setTextColor(ui.onFill(C.INK3, C.INK_ON_FILL)); isDuplicateParentStateEnabled = true }
                .also(texts::addView)
        }
        line.addView(texts, lp(0, WRAP, 1f))
        f.addView(line, flp(MATCH, ui.px(heightDp)))
        return f to subView
    }

    private fun scrim(act: MainActivity, color: Int) = FrameLayout(act).apply {
        setBackgroundColor(color)
        isClickable = true
        clipChildren = false
    }

    // ------------------------------------------------------------- options

    fun appOptions(act: MainActivity, app: AppInfo, onDone: (() -> Unit)? = null) {
        val ui = act.ui
        val pkg = app.packageName
        val pinned = Home.pinned(act.apps, act.layout)
        val position = pinned.indexOfFirst { it.packageName == pkg }
        val actions = buildList<Triple<Int, String, () -> Unit>> {
            if (position < 0 && Home.canPin(act.apps, act.layout)) {
                add(Triple(Ic.ADD, "Fijar en Tus apps") { act.saveLayout(Home.pin(pkg, act.apps, act.layout)) })
            }
            if (position >= 0) {
                add(Triple(Ic.REMOVE, "Quitar de Tus apps") { act.saveLayout(Home.unpin(pkg, act.apps, act.layout)) })
                if (position > 0) add(Triple(Ic.LEFT, "Mover a la izquierda") { act.saveLayout(Home.shift(pkg, -1, act.apps, act.layout)) })
                if (position < pinned.size - 1) add(Triple(Ic.RIGHT, "Mover a la derecha") { act.saveLayout(Home.shift(pkg, 1, act.apps, act.layout)) })
            }
            add(Triple(Ic.HIDE, "Ocultar") { act.saveLayout(Home.hide(pkg, act.apps, act.layout)) })
            add(Triple(Ic.INFO, "Información de la app") { act.openAppInfo(pkg) })
        }

        val root = scrim(act, 0xCC06070B.toInt())
        val panel = ui.horizontal().apply {
            background = ui.rounded(C.SURFACE2, 14f, 0.5f, 0x12FFFFFF)
            setPadding(ui.px(28), ui.px(28), ui.px(28), ui.px(28))
            clipChildren = false
        }
        val left = ui.vertical()
        val art = FrameLayout(act).also { ui.clipRounded(it, 8f) }
        AppCard.appArt(ui, app, 220f * 9 / 16)(art)
        left.addView(art, lp(ui.px(220), ui.px(220f * 9 / 16)))
        left.addView(ui.text(app.label, 22f, 700, spacing = -0.2f).apply { maxLines = 2 }, lp(ui.px(220), WRAP).apply { topMargin = ui.px(14) })
        left.addView(ui.text(if (position >= 0) "Fijada · posición ${position + 1} de ${pinned.size}" else "No fijada", 12f, 600, C.INK3),
            lp(WRAP, WRAP).apply { topMargin = ui.px(3) })
        panel.addView(left, lp(ui.px(220), WRAP))

        val right = ui.vertical().apply { clipChildren = false }
        actions.forEachIndexed { i, (icon, label, run) ->
            val (r, _) = row(ui, icon, label, heightDp = 40f) {
                act.pop()
                run()
                onDone?.invoke()
            }
            right.addView(r, lp(MATCH, WRAP).apply { if (i > 0) topMargin = ui.px(4) })
        }
        right.addView(hints(ui, "Atrás" to "Cerrar"), lp(WRAP, WRAP).apply { topMargin = ui.px(14); marginStart = ui.px(3) })
        panel.addView(right, lp(0, WRAP, 1f).apply { marginStart = ui.px(29) })

        root.addView(panel, flp(ui.px(590), WRAP, Gravity.CENTER))
        enter(panel, dy = 6f)
        act.push(root)
    }

    // -------------------------------------------------------------- inputs

    /** Drop-down under the top-right buttons with the HDMI inputs. */
    fun inputs(act: MainActivity) {
        val ui = act.ui
        val root = scrim(act, 0x8006070B.toInt())
        val panel = ui.vertical().apply {
            background = ui.rounded(C.SURFACE2, 14f, 0.5f, 0x12FFFFFF)
            setPadding(ui.px(10), ui.px(12), ui.px(10), ui.px(10))
            clipChildren = false
        }
        panel.addView(ui.text("ENTRADAS", 12f, 800, C.INK2, spacing = 2.2f), lp(WRAP, WRAP).apply { setMargins(ui.px(9), 0, 0, ui.px(6)) })
        val hdmi = act.inputs.filter { it.kind == "hdmi" }
        var first: View? = null
        hdmi.forEach { input ->
            val (r, _) = row(ui, Ic.HDMI, input.label, heightDp = 40f) {
                act.pop()
                act.openInput(input.id)
            }
            if (first == null) first = r
            panel.addView(r, lp(MATCH, WRAP))
        }
        root.addView(panel, flp(ui.px(220), WRAP, Gravity.END or Gravity.TOP).apply {
            setMargins(0, ui.px(80), ui.px(SIDE + 40), 0)
        })
        enter(panel, dy = -6f)
        act.push(root)
        first?.let { f -> f.post { f.requestFocus() } }
    }

    // ------------------------------------------------------------ settings

    fun settings(act: MainActivity) {
        val ui = act.ui
        val root = scrim(act, 0xA806070B.toInt())
        val panel = ui.vertical().apply {
            setBackgroundColor(C.SURFACE1)
            setPadding(ui.px(29), ui.px(40), ui.px(SIDE - 22), ui.px(28))
            clipChildren = false
        }
        panel.addView(ui.text("Ajustes", 28f, 700, spacing = -0.56f), lp(WRAP, WRAP).apply { marginStart = ui.px(3) })

        fun section(title: String, top: Float) = panel.addView(ui.text(title, 12f, 800, C.INK2, spacing = 2.2f),
            lp(WRAP, WRAP).apply { topMargin = ui.px(top); bottomMargin = ui.px(5); marginStart = ui.px(3) })
        fun add(v: View) = panel.addView(v, lp(MATCH, WRAP).apply { bottomMargin = ui.px(0) })

        section("PANTALLA", 18f)
        val value = ui.text("${act.layout.columns}", 24f, 700, tabular = true).apply {
            gravity = Gravity.CENTER
            setTextColor(ui.onFill(C.INK))
            isDuplicateParentStateEnabled = true
        }
        fun setColumns(delta: Int) {
            act.saveLayout(act.layout.copy(columns = Home.columns(act.layout.columns, delta)))
            value.text = "${act.layout.columns}"
        }
        val (columns, _) = row(ui, null, "Columnas de la grilla", "Apps por fila en Tus apps", 50f) { setColumns(0) }
        (((columns.getChildAt(0) as LinearLayout))).apply {
            addView(ui.icon(Ic.CHEVRON_LEFT, 18f).apply { setTextColor(ui.onFill(C.INK3, C.INK_ON_FILL)); isDuplicateParentStateEnabled = true })
            addView(value, lp(ui.px(26), WRAP))
            addView(ui.icon(Ic.CHEVRON_RIGHT, 18f).apply { setTextColor(ui.onFill(C.INK3)); isDuplicateParentStateEnabled = true })
        }
        columns.setOnKeyListener { _, code, e ->
            if (e.action != KeyEvent.ACTION_DOWN) return@setOnKeyListener code == KeyEvent.KEYCODE_DPAD_LEFT || code == KeyEvent.KEYCODE_DPAD_RIGHT
            when (code) {
                KeyEvent.KEYCODE_DPAD_LEFT -> { setColumns(-1); true }
                KeyEvent.KEYCODE_DPAD_RIGHT -> { setColumns(1); true }
                else -> false
            }
        }
        add(columns)
        val hidden = Home.hidden(act.apps, act.layout)
        add(row(ui, null, "Apps ocultas", if (hidden.isEmpty()) "Ninguna" else "${hidden.size} · OK muestra la primera", 50f) {
            Home.hidden(act.apps, act.layout).firstOrNull()?.let { act.saveLayout(Home.unhide(it.packageName, act.layout)) }
            act.pop(); settings(act)
        }.first)

        section("IPHONE", 12f)
        val connected = act.clients.isNotEmpty()
        val address = act.companionAddress()
        val (phone, phoneSub) = row(ui, Ic.PHONE, if (connected) act.clients.joinToString(", ") else "App del iPhone",
            if (connected) "Conectado ahora" else if (address.isEmpty()) "Esperando conexión" else "Esperando conexión · $address", 50f) {}
        if (connected) phoneSub?.setTextColor(ui.onFill(C.GREEN, C.INK_ON_FILL))
        add(phone)
        var confirm = false
        lateinit var revokeSub: TextView
        val (revoke, sub) = row(ui, Ic.UNLINK, "Dispositivos vinculados", "Desvincular todos", 50f) {
            if (!confirm) {
                confirm = true
                revokeSub.text = "OK otra vez para desvincular todos"
            } else {
                confirm = false
                act.revokeDevices()
                revokeSub.text = "Listo · el iPhone debe vincularse de nuevo"
            }
        }
        revokeSub = sub!!
        add(revoke)

        section("SISTEMA", 12f)
        add(row(ui, Ic.SETTINGS, "Ajustes del sistema", "Red, pantalla, sonido, protector", 50f) { act.openSystemSettings() }.first)

        panel.addView(View(act), lp(1, 0, 1f))
        panel.addView(hints(ui, "‹  ›" to "Cambiar", "Atrás" to "Cerrar"), lp(WRAP, WRAP).apply { marginStart = ui.px(3) })

        root.addView(panel, flp(ui.px(400), MATCH, Gravity.END))
        panel.translationX = ui.pxf(400f)
        panel.animate().translationX(0f).setDuration(Motion.PANEL).setInterpolator(Motion.standard).start()
        act.push(root)
        columns.post { columns.requestFocus() }
    }

    // ------------------------------------------------------------ all apps

    fun allApps(act: MainActivity) {
        val ui = act.ui
        val root = FrameLayout(act).apply { setBackgroundColor(C.HOME_BG); isClickable = true }
        val col = ui.vertical().apply { setPadding(0, ui.px(40), 0, 0) }
        val head = ui.horizontal().apply { gravity = Gravity.BOTTOM; setPadding(ui.px(SIDE), 0, ui.px(SIDE), 0) }
        val titles = ui.vertical()
        titles.addView(ui.text("INICIO  ›", 12f, 800, C.INK2, spacing = 2.2f), lp(WRAP, WRAP))
        val count = ui.text("", 15f, 600, C.INK3)
        val titleRow = ui.horizontal().apply { gravity = Gravity.BOTTOM }
        titleRow.addView(ui.text("Todas las apps", 32f, 700, spacing = -0.64f))
        titleRow.addView(count, lp(WRAP, WRAP).apply { marginStart = ui.px(10); bottomMargin = ui.px(4) })
        titles.addView(titleRow, lp(WRAP, WRAP).apply { topMargin = ui.px(4) })
        head.addView(titles, lp(0, WRAP, 1f))
        head.addView(hints(ui, "Mantén|OK" to "Opciones", "Atrás" to "Inicio"), lp(WRAP, WRAP).apply { bottomMargin = ui.px(6) })
        col.addView(head, lp(MATCH, WRAP))

        val grid = ui.vertical().apply {
            clipChildren = false
            clipToPadding = false
            setPadding(ui.px(SIDE), ui.px(16), ui.px(SIDE), ui.px(40))
        }
        val scroll = ScrollView(act).apply {
            isVerticalScrollBarEnabled = false
            clipToPadding = false
            isFillViewport = true
            addView(grid)
        }
        col.addView(scroll, lp(MATCH, 0, 1f).apply { topMargin = ui.px(6) })
        root.addView(col, flp(MATCH, MATCH))

        fun build() {
            val focused = (act.currentFocus?.tag as? String)
            grid.removeAllViews()
            val apps = Home.visible(act.apps, act.layout)
            count.text = "${apps.size}"
            val cols = 5
            val w = (960f - 2 * SIDE - 16f * (cols - 1)) / cols
            apps.chunked(cols).forEach { chunk ->
                val row = ui.horizontal().apply { clipChildren = false; gravity = Gravity.TOP }
                chunk.forEachIndexed { i, app ->
                    val card = AppCard(ui, w, app.label, onSelect = { act.launch(app.packageName) },
                        onLongPress = { appOptions(act, app) { if (act.isTop(root)) rebuild?.invoke() } },
                        pinned = Home.isPinned(app.packageName, act.apps, act.layout), art = AppCard.appArt(ui, app, w * 9 / 16))
                    card.frame.tag = "all:${app.packageName}"
                    row.addView(card, lp(WRAP, WRAP).apply { if (i > 0) marginStart = ui.px(16) })
                }
                grid.addView(row, lp(MATCH, WRAP))
            }
            val target = focused?.let { grid.findViewWithTag<View>(it) }
                ?: ((grid.getChildAt(0) as? LinearLayout)?.getChildAt(0) as? AppCard)?.frame
            target?.post { target.requestFocus() }
        }
        rebuild = ::build
        build()
        act.push(root)
    }

    /** Refreshes the open "Todas las apps" after an option changed the layout. */
    private var rebuild: (() -> Unit)? = null

    // -------------------------------------------------------------- pairing

    fun pairing(act: MainActivity, code: String, client: String?): View {
        val ui = act.ui
        val root = scrim(act, 0xEB06070B.toInt()).apply { isFocusable = true }
        val col = ui.vertical().apply { gravity = Gravity.CENTER_HORIZONTAL }
        col.addView(ui.text("VINCULAR IPHONE", 12f, 800, C.TEAL, spacing = 2.4f), lp(WRAP, WRAP))
        col.addView(ui.text("Escribe este código en tu iPhone", 32f, 700, spacing = -0.64f), lp(WRAP, WRAP).apply { topMargin = ui.px(8) })
        col.addView(ui.text("${client ?: "Un iPhone"} quiere conectarse", 15f, 500, C.INK2), lp(WRAP, WRAP).apply { topMargin = ui.px(7) })
        val boxes = ui.horizontal().apply { contentDescription = code }
        val half = (code.length + 1) / 2
        code.forEachIndexed { i, c ->
            if (i == half) boxes.addView(View(act).apply { background = ui.rounded(0xFF3A3E4E.toInt(), 2f) },
                lp(ui.px(14), ui.px(4)).apply { setMargins(ui.px(8), 0, ui.px(8), 0) })
            boxes.addView(ui.text(c.toString(), 66f, 700, tabular = true).apply {
                gravity = Gravity.CENTER
                background = ui.rounded(C.SURFACE2, 12f, 1f, 0x1AFFFFFF)
            }, lp(ui.px(78), ui.px(98)).apply { setMargins(ui.px(5), 0, ui.px(5), 0) })
        }
        col.addView(boxes, lp(WRAP, WRAP).apply { topMargin = ui.px(36) })
        val bar = android.widget.ProgressBar(act, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = TTL_S
            progress = TTL_S
            progressTintList = android.content.res.ColorStateList.valueOf(C.TEAL)
            progressBackgroundTintList = android.content.res.ColorStateList.valueOf(0x14FFFFFF)
        }
        col.addView(bar, lp(ui.px(390), ui.px(4)).apply { topMargin = ui.px(32) })
        val status = ui.horizontal()
        status.addView(View(act).apply { background = ui.rounded(C.TEAL, 3f) }, lp(ui.px(6), ui.px(6)))
        status.addView(ui.text("Esperando al iPhone…", 13f, 600, C.INK2), lp(0, WRAP, 1f).apply { marginStart = ui.px(6) })
        val left = ui.text("", 13f, 600, C.INK3, tabular = true)
        status.addView(left)
        col.addView(status, lp(ui.px(390), WRAP).apply { topMargin = ui.px(9) })
        root.addView(col, flp(WRAP, WRAP, Gravity.CENTER))

        val shownAt = System.currentTimeMillis()
        val h = Handler(Looper.getMainLooper())
        val tick = object : Runnable {
            override fun run() {
                val s = (TTL_S - (System.currentTimeMillis() - shownAt) / 1000).toInt().coerceAtLeast(0)
                bar.progress = s
                left.text = "Caduca en ${s / 60}:${(s % 60).toString().padStart(2, '0')}"
                if (s > 0 && root.isAttachedToWindow) h.postDelayed(this, 1000)
            }
        }
        root.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) = tick.run()
            override fun onViewDetachedFromWindow(v: View) = h.removeCallbacks(tick)
        })
        enter(col, dy = 6f)
        return root
    }

    private const val TTL_S = 120

    private fun enter(v: View, dy: Float) {
        v.alpha = 0f
        v.translationY = dy * v.resources.displayMetrics.density
        v.animate().alpha(1f).translationY(0f).setDuration(Motion.OVERLAY).setInterpolator(Motion.standard).start()
    }
}
