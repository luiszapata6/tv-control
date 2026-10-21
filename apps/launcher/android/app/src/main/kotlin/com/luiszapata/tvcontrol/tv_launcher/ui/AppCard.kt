package com.luiszapata.tvcontrol.tv_launcher.ui

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min

/** Banners, icons and app colours, loaded off the main thread once per package. */
object Art {
    class Loaded(val banner: Drawable.ConstantState?, val icon: Drawable.ConstantState?, val tint: Int)

    private val io = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())
    private val cache = HashMap<String, Loaded>() // main thread only
    private val waiting = HashMap<String, MutableList<(Loaded) -> Unit>>()

    fun get(context: Context, pkg: String, done: (Loaded) -> Unit) {
        cache[pkg]?.let { return done(it) }
        waiting[pkg]?.let { it.add(done); return }
        waiting[pkg] = mutableListOf(done)
        val pm = context.applicationContext.packageManager
        io.execute {
            val loaded = try {
                val banner = tvBanner(pm, pkg)
                val icon = if (banner == null) pm.getApplicationIcon(pkg) else null
                Loaded(banner?.constantState, icon?.constantState, dominantColor(banner ?: icon))
            } catch (e: PackageManager.NameNotFoundException) {
                Loaded(null, null, 0)
            }
            main.post {
                cache[pkg] = loaded
                waiting.remove(pkg)?.forEach { it(loaded) }
            }
        }
    }

    /**
     * Many apps (Kick, Disney+...) declare their banner on the TV launch
     * activity, not the application; check it first, like the stock launcher.
     */
    fun tvBanner(pm: PackageManager, pkg: String): Drawable? =
        pm.getLeanbackLaunchIntentForPackage(pkg)?.let { runCatching { pm.getActivityBanner(it) }.getOrNull() }
            ?: pm.getApplicationBanner(pkg)

    /** Apps were installed, updated or removed. */
    fun clear() = cache.clear()

    /**
     * Average of a 12x12 thumbnail where saturated pixels weigh most, so a
     * white banner with a red logo gives red, not white. 0 if unknown.
     */
    fun dominantColor(d: Drawable?): Int {
        if (d == null) return 0
        val bmp = Bitmap.createBitmap(12, 12, Bitmap.Config.ARGB_8888)
        val copy = d.constantState?.newDrawable()?.mutate() ?: d
        copy.setBounds(0, 0, 12, 12)
        copy.draw(Canvas(bmp))
        var r = 0.0; var g = 0.0; var b = 0.0; var total = 0.0
        for (y in 0 until 12) for (x in 0 until 12) {
            val p = bmp.getPixel(x, y)
            val pr = Color.red(p); val pg = Color.green(p); val pb = Color.blue(p)
            val hi = max(pr, max(pg, pb)); val lo = min(pr, min(pg, pb))
            val sat = if (hi == 0) 0.0 else (hi - lo).toDouble() / hi
            val w = Color.alpha(p) / 255.0 * (0.03 + sat * sat)
            r += pr * w; g += pg * w; b += pb * w; total += w
        }
        bmp.recycle()
        if (total == 0.0) return 0
        return Color.rgb((r / total).toInt(), (g / total).toInt(), (b / total).toInt())
    }

    /** Background for icon-only apps: their colour, dark and muted (or a hue from the name). */
    fun darkTint(color: Int, label: String): Int {
        val hsv = FloatArray(3)
        if (color == 0) {
            hsv[0] = ((label.sumOf { it.code } * 37) % 360).toFloat(); hsv[1] = 0.45f
        } else {
            Color.colorToHSV(color, hsv); hsv[1] *= 0.6f
        }
        hsv[2] = 0.24f
        return Color.HSVToColor(hsv)
    }
}

/**
 * App card for grids: 16:9 art (banner edge to edge, or icon on its tint)
 * and the name under the card while focused.
 */
class AppCard(
    private val ui: Ui,
    widthDp: Float,
    label: String,
    onSelect: () -> Unit,
    onLongPress: (() -> Unit)? = null,
    pinned: Boolean = false,
    art: (FrameLayout) -> Unit,
) : LinearLayout(ui.context) {
    val frame = FocusFrame(ui, FocusFrame.Look.CARD, 8f)
    private val name = ui.text(label, 13f, 700).apply {
        gravity = Gravity.CENTER
        alpha = 0f
    }

    init {
        orientation = VERTICAL
        clipChildren = false
        val w = ui.px(widthDp)
        val h = ui.px(widthDp * 9 / 16)
        val content = FrameLayout(ui.context).also { ui.clipRounded(it, 8f) }
        content.foreground = ui.rounded(0, 8f, 0.5f, 0x12FFFFFF)
        art(content)
        frame.addView(content, flp(w, h))
        if (pinned) {
            frame.addView(View(ui.context).apply { background = ui.rounded(C.AMBER, 4f, 1.5f, 0xD90A0B10.toInt()) },
                flp(ui.px(8), ui.px(8), Gravity.END or Gravity.TOP).apply { setMargins(0, ui.px(10), ui.px(10), 0) })
        }
        frame.setOnClickListener { onSelect() }
        frame.onLongPress = onLongPress
        frame.contentDescription = label
        frame.setOnFocusChangeListener { _, f ->
            name.animate().alpha(if (f) 1f else 0f).setDuration(if (f) Motion.FOCUS_IN else Motion.FOCUS_OUT).start()
        }
        addView(frame, lp(w + 2 * frame.inset, h + 2 * frame.inset).apply { setMargins(-frame.inset, -frame.inset, -frame.inset, -frame.inset) })
        addView(name, lp(MATCH, ui.px(18)).apply { topMargin = ui.px(12) })
    }

    companion object {
        /** Fills [box] with the app's art once it is loaded (skeleton meanwhile). */
        fun appArt(ui: Ui, app: AppInfo, heightDp: Float): (FrameLayout) -> Unit = { box ->
            box.setBackgroundColor(C.SKELETON)
            val skeleton = ui.text(app.label, 12f, 700, C.INK3).apply { gravity = Gravity.CENTER }
            box.addView(skeleton, flp(MATCH, MATCH))
            Art.get(ui.context, app.packageName) { a ->
                box.removeAllViews()
                val banner = a.banner?.newDrawable(ui.context.resources)
                if (banner != null) {
                    box.addView(ImageView(ui.context).apply {
                        setImageDrawable(banner)
                        scaleType = ImageView.ScaleType.CENTER_CROP
                    }, flp(MATCH, MATCH))
                } else {
                    box.setBackgroundColor(Art.darkTint(a.tint, app.label))
                    val col = ui.vertical().apply { gravity = Gravity.CENTER }
                    val side = ui.px(heightDp * 0.4f)
                    col.addView(ImageView(ui.context).apply {
                        setImageDrawable(a.icon?.newDrawable(ui.context.resources))
                        scaleType = ImageView.ScaleType.FIT_CENTER
                        ui.clipRounded(this, heightDp * 0.4f * 0.24f)
                    }, lp(side, side))
                    col.addView(ui.text(app.label, 12f, 700).apply { gravity = Gravity.CENTER },
                        lp(WRAP, WRAP).apply { topMargin = ui.px(heightDp * 0.07f) })
                    box.addView(col, flp(MATCH, MATCH))
                }
            }
        }

        /** The "Todas las apps" card at the end of the favourites. */
        fun allAppsArt(ui: Ui, count: Int): (FrameLayout) -> Unit = { box ->
            box.background = ui.rounded(C.SURFACE2, 0f)
            val col = ui.vertical().apply { gravity = Gravity.CENTER }
            col.addView(ui.icon(Ic.APPS, 26f, C.INDIGO_LIGHT))
            col.addView(ui.text("Todas las apps", 13f, 700).apply { gravity = Gravity.CENTER }, lp(WRAP, WRAP).apply { topMargin = ui.px(6) })
            col.addView(ui.text("$count instaladas", 12f, 500, C.INK3).apply { gravity = Gravity.CENTER }, lp(WRAP, WRAP).apply { topMargin = ui.px(2) })
            box.addView(col, flp(MATCH, MATCH))
        }
    }
}
