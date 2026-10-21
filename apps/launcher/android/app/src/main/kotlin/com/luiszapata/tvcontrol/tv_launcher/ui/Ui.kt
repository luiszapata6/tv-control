package com.luiszapata.tvcontrol.tv_launcher.ui

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Outline
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.LayerDrawable
import android.graphics.drawable.StateListDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.animation.PathInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.luiszapata.tvcontrol.tv_launcher.R
import kotlin.math.roundToInt

/** Design tokens (Claude Design "TV Launcher" v2). Sizes are dp on a 960x540 canvas. */
object C {
    const val BG = 0xFF0A0B10.toInt()
    const val HOME_BG = 0xFF08090D.toInt()
    const val SURFACE1 = 0xFF12141C.toInt()
    const val SURFACE2 = 0xFF171923.toInt()
    const val SKELETON = 0xFF181A24.toInt()
    const val INK = 0xFFF4F4F8.toInt()
    const val INK2 = 0xFFB9BCCB.toInt()
    const val INK3 = 0xFF8A8EA0.toInt()
    const val INK4 = 0xFF6F7385.toInt()
    const val INK_SOFT = 0xFFE4E5EE.toInt()
    const val INK_ON_FILL = 0xFF4A4D5C.toInt()
    const val INDIGO_LIGHT = 0xFFA5A6FF.toInt()
    const val AMBER = 0xFFF3B74F.toInt()
    const val TEAL = 0xFF45CFC0.toInt()
    const val GREEN = 0xFF4ADE80.toInt()
    const val HALO = 0x596C6CF2
    const val ROW = 0x0AFFFFFF
}

/** Material icon codepoints (res/font/material_icons.otf is a subset with only these). */
object Ic {
    const val TUNE = 0xF0258
    const val HDMI = 0xF015E
    const val APPS = 0xF56D
    const val PHONE = 0xF007F
    const val ADD = 0xF52C
    const val REMOVE = 0xF00EB
    const val LEFT = 0xF572
    const val RIGHT = 0xF57A
    const val HIDE = 0xF4A0
    const val INFO = 0xF815
    const val UNLINK = 0xF859
    const val SETTINGS = 0xF36E
    const val CHEVRON_LEFT = 0xF63A
    const val CHEVRON_RIGHT = 0xF63B
    const val SUN = 0xF4BC
    const val MOON = 0xF214
    const val CLOUD_SUN = 0xF4B8
    const val CLOUD_MOON = 0xF216
    const val CLOUD = 0xEF62
    const val RAIN = 0xF0695
    const val SNOW = 0xE037
    const val STORM = 0xF071B
    const val CLOSE = 0xF647

    fun weather(code: Int, isDay: Boolean): Int = when (code) {
        0, 1 -> if (isDay) SUN else MOON
        2 -> if (isDay) CLOUD_SUN else CLOUD_MOON
        3, 45, 48 -> CLOUD
        in 51..67, 80, 81, 82 -> RAIN
        71, 73, 75, 77, 85, 86 -> SNOW
        95, 96, 99 -> STORM
        else -> CLOUD
    }
}

object Motion {
    val standard = PathInterpolator(0.2f, 0.8f, 0.2f, 1f)
    val exit = PathInterpolator(0.4f, 0f, 0.2f, 1f)
    const val FOCUS_IN = 200L
    const val FOCUS_OUT = 160L
    const val PRESS = 90L
    const val OVERLAY = 240L
    const val PANEL = 280L
}

/** Builds views in design dp (the screen is 960 dp wide on any TV). */
class Ui(val context: Context) {
    private val scale = context.resources.displayMetrics.widthPixels / 960f
    fun px(dp: Float): Int = (dp * scale).roundToInt()
    fun px(dp: Int): Int = px(dp.toFloat())
    fun pxf(dp: Float): Float = dp * scale

    private val fonts = HashMap<Int, Typeface>()
    fun font(weight: Int): Typeface = fonts.getOrPut(weight) {
        context.resources.getFont(
            when (weight) {
                200 -> R.font.manrope_200
                300 -> R.font.manrope_300
                500 -> R.font.manrope_500
                600 -> R.font.manrope_600
                800 -> R.font.manrope_800
                else -> R.font.manrope_700
            },
        )
    }
    val icons: Typeface by lazy { context.resources.getFont(R.font.material_icons) }

    /** [color] may be a ColorStateList so the text inverts on a focused fill. */
    fun text(s: CharSequence, size: Float, weight: Int, color: Int = C.INK, spacing: Float = 0f, tabular: Boolean = false) =
        TextView(context).apply {
            text = s
            typeface = font(weight)
            setTextSize(TypedValue.COMPLEX_UNIT_PX, pxf(size))
            setTextColor(color)
            includeFontPadding = false
            // singleLine, not maxLines: custom fonts measure a hair short and the last word would wrap away.
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.END
            if (spacing != 0f) letterSpacing = spacing / size
            if (tabular) fontFeatureSettings = "tnum"
        }

    fun icon(code: Int, size: Float, color: Int = C.INK) = TextView(context).apply {
        text = String(Character.toChars(code))
        typeface = icons
        setTextSize(TypedValue.COMPLEX_UNIT_PX, pxf(size))
        setTextColor(color)
        includeFontPadding = false
        gravity = Gravity.CENTER
    }

    fun rounded(color: Int, radiusDp: Float, strokeDp: Float = 0f, strokeColor: Int = 0) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = pxf(radiusDp)
        if (strokeDp > 0) setStroke(px(strokeDp), strokeColor)
    }

    fun vertical() = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
    fun horizontal() = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }

    fun space(w: Float = 0f, h: Float = 0f) = View(context).apply { layoutParams = LinearLayout.LayoutParams(px(w), px(h)) }

    /** Clips [v] to a rounded rect on the GPU (no per-frame mask work). */
    fun clipRounded(v: View, radiusDp: Float) {
        val r = pxf(radiusDp)
        v.outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(view: View, outline: Outline) = outline.setRoundRect(0, 0, view.width, view.height, r)
        }
        v.clipToOutline = true
    }

    /** Text colour that inverts when the parent [FocusFrame] is focused. */
    fun onFill(rest: Int, focused: Int = C.BG) = ColorStateList(
        arrayOf(intArrayOf(android.R.attr.state_focused), intArrayOf()),
        intArrayOf(focused, rest),
    )
}

fun lp(w: Int, h: Int, weight: Float = 0f) = LinearLayout.LayoutParams(w, h, weight)
fun flp(w: Int, h: Int, gravity: Int = Gravity.NO_GRAVITY) = FrameLayout.LayoutParams(w, h, gravity)
const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT

/**
 * A D-pad focusable element. [Look.CARD]: content keeps its look, the frame
 * scales 1.10 and shows a white ring over a background gap plus an indigo
 * halo (crisp, no blur: cheap on weak TV GPUs). [Look.FILL]: rows and buttons
 * invert to a light fill and scale 1.03. Children see the focused state
 * (duplicateParentState) to invert their colours.
 */
class FocusFrame(private val ui: Ui, val look: Look, radiusDp: Float, restColor: Int = C.ROW, restStroke: Int = 0) :
    FrameLayout(ui.context) {
    enum class Look { CARD, FILL }

    /** Ring + halo thickness outside a card's content. */
    val inset: Int = if (look == Look.CARD) ui.px(7) else 0
    var focusedScale = if (look == Look.CARD) 1.10f else 1.03f
    var onLongPress: (() -> Unit)? = null

    init {
        isFocusable = true
        isFocusableInTouchMode = false
        clipChildren = false
        background = if (look == Look.CARD) cardRing(radiusDp) else fill(radiusDp, restColor, restStroke)
        setPadding(inset, inset, inset, inset)
        setOnLongClickListener { onLongPress?.invoke(); onLongPress != null }
        // Z order only (focused card above its neighbours), never a shadow.
        outlineProvider = null
    }

    private fun cardRing(r: Float): Drawable {
        val ring = LayerDrawable(
            arrayOf(
                ui.rounded(C.HALO, r + 7),
                ui.rounded(C.INK, r + 3.5f),
                ui.rounded(C.BG, r + 1.5f),
            ),
        ).apply {
            setLayerInset(1, ui.px(3.5f), ui.px(3.5f), ui.px(3.5f), ui.px(3.5f))
            setLayerInset(2, ui.px(5.5f), ui.px(5.5f), ui.px(5.5f), ui.px(5.5f))
        }
        return StateListDrawable().apply {
            addState(intArrayOf(android.R.attr.state_focused), ring)
            addState(intArrayOf(), null)
            setEnterFadeDuration(Motion.FOCUS_IN.toInt())
            setExitFadeDuration(Motion.FOCUS_OUT.toInt())
        }
    }

    private fun fill(r: Float, rest: Int, stroke: Int) = StateListDrawable().apply {
        val focused = LayerDrawable(arrayOf(ui.rounded(C.HALO, r + 3), ui.rounded(C.INK, r))).apply {
            setLayerInset(1, ui.px(3), ui.px(3), ui.px(3), ui.px(3))
        }
        addState(intArrayOf(android.R.attr.state_focused), focused)
        addState(intArrayOf(), LayerDrawable(arrayOf(ui.rounded(0, r + 3), ui.rounded(rest, r, if (stroke != 0) 0.5f else 0f, stroke))).apply {
            setLayerInset(1, ui.px(3), ui.px(3), ui.px(3), ui.px(3))
        })
        setEnterFadeDuration(Motion.FOCUS_IN.toInt())
        setExitFadeDuration(Motion.FOCUS_OUT.toInt())
    }

    override fun onFocusChanged(gainFocus: Boolean, direction: Int, previouslyFocusedRect: android.graphics.Rect?) {
        super.onFocusChanged(gainFocus, direction, previouslyFocusedRect)
        animate().cancel()
        val s = if (gainFocus) focusedScale else 1f
        animate().scaleX(s).scaleY(s).setDuration(if (gainFocus) Motion.FOCUS_IN else Motion.FOCUS_OUT)
            .setInterpolator(if (gainFocus) Motion.standard else Motion.exit).start()
        translationZ = if (gainFocus) 1f else 0f
    }

    private var longFired = false

    /**
     * Hold OK opens the options as soon as the remote reports a long press
     * (repeat / FLAG_LONG_PRESS), not only after View's own timer: some
     * remotes send the release right after, which View would treat as a click.
     */
    override fun dispatchKeyEvent(event: android.view.KeyEvent): Boolean {
        val select = event.keyCode == android.view.KeyEvent.KEYCODE_DPAD_CENTER ||
            event.keyCode == android.view.KeyEvent.KEYCODE_ENTER || event.keyCode == android.view.KeyEvent.KEYCODE_NUMPAD_ENTER
        val long = onLongPress
        if (select && long != null) {
            if (event.action == android.view.KeyEvent.ACTION_DOWN) {
                if (event.repeatCount == 0) longFired = false
                else if (!longFired) {
                    longFired = true
                    cancelLongPress()
                    isPressed = false
                    long()
                    return true
                }
            } else if (event.action == android.view.KeyEvent.ACTION_UP && longFired) {
                longFired = false
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun setPressed(pressed: Boolean) {
        val was = isPressed
        super.setPressed(pressed)
        if (was == pressed || !isFocused) return
        val s = if (pressed) (if (look == Look.CARD) 1.04f else 1f) else focusedScale
        animate().scaleX(s).scaleY(s).setDuration(if (pressed) Motion.PRESS else Motion.FOCUS_IN).setInterpolator(Motion.standard).start()
    }
}
