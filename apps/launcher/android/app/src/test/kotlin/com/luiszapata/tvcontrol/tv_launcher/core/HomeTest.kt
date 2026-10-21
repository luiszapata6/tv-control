package com.luiszapata.tvcontrol.tv_launcher.core

import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class HomeTest {
    private fun app(pkg: String, label: String, system: Boolean = false) = AppInfo(pkg, label, 1, system)
    private val yt = app("yt", "YouTube")
    private val nf = app("nf", "Netflix")
    private val dp = app("dp", "Disney+")
    private val play = app("play", "Google Play Store", system = true)
    private val apps = listOf(dp, play, nf, yt)

    @Test fun `pinned follows the layout order and skips uninstalled apps`() {
        val l = Layout(order = listOf("nf", "gone", "yt"))
        assertEquals(listOf("Netflix", "YouTube"), Home.pinned(apps, l).map { it.label })
    }

    @Test fun `without a layout, non-system apps are suggested and the first edit materializes them`() {
        assertEquals(listOf("Disney+", "Netflix", "YouTube"), Home.pinned(apps, Layout()).map { it.label })
        val hidden = Home.hide("dp", apps, Layout())
        assertEquals(listOf("nf", "yt"), hidden.order)
        assertEquals(listOf("dp"), hidden.hidden)
        assertFalse(Home.visible(apps, hidden).any { it.packageName == "dp" })
    }

    @Test fun `at most nine favourites, and pinning a tenth does nothing`() {
        val many = (1..11).map { app("p$it", "App $it") }
        val full = Layout(order = many.take(9).map { it.packageName })
        assertEquals(9, Home.pinned(many, Layout(order = many.map { it.packageName })).size)
        assertFalse(Home.canPin(many, full))
        assertEquals(full.order, Home.pin("p10", many, full).order)
        assertEquals(listOf("p1", "p2", "p9"), Home.pin("p9", many, Layout(order = listOf("p1", "p2"))).order)
    }

    @Test fun `shift moves one step and stops at the ends`() {
        val l = Layout(order = listOf("nf", "yt", "dp"))
        assertEquals(listOf("yt", "nf", "dp"), Home.shift("nf", 1, apps, l).order)
        assertEquals(l.order, Home.shift("nf", -1, apps, l).order)
        assertEquals(listOf("nf", "yt"), Home.unpin("dp", apps, l).order)
    }

    @Test fun `columns cycle on OK and stop at the ends with the arrows`() {
        assertEquals(7, Home.columns(6, 0))
        assertEquals(Layout.MIN_COLUMNS, Home.columns(Layout.MAX_COLUMNS, 0))
        assertEquals(Layout.MAX_COLUMNS, Home.columns(Layout.MAX_COLUMNS, 1))
        assertEquals(5, Home.columns(6, -1))
    }

    @Test fun `recent apps are newest first, installed and not hidden`() {
        val used = mapOf("yt" to 30L, "nf" to 50L, "gone" to 99L, "dp" to 10L)
        assertEquals(listOf("Netflix", "YouTube", "Disney+"), Home.recent(used, apps, Layout()).map { it.label })
        assertEquals(listOf("Netflix"), Home.recent(used, apps, Layout(hidden = listOf("yt")), limit = 1).map { it.label })
    }

    @Test fun `greeting changes at 5, 12 and 19`() {
        assertEquals("BUENAS NOCHES AMIGUE", Home.greeting(4))
        assertEquals("BUENOS DÍAS AMIGUE", Home.greeting(5))
        assertEquals("BUENOS DÍAS AMIGUE", Home.greeting(11))
        assertEquals("BUENAS TARDES AMIGUE", Home.greeting(12))
        assertEquals("BUENAS TARDES AMIGUE", Home.greeting(18))
        assertEquals("BUENAS NOCHES AMIGUE", Home.greeting(19))
    }

    @Test fun `dates in Spanish`() {
        val c = Calendar.getInstance().apply { set(2026, Calendar.OCTOBER, 18) }
        assertEquals("Domingo 18 de octubre", Home.date(c))
    }

    @Test fun `open-meteo parsing`() {
        val w = Weather.parse("""{"current":{"temperature_2m":17.6,"weather_code":63,"is_day":0}}""")!!
        assertEquals("18°", w.temperatureLabel)
        assertEquals("Lluvia", w.label)
        assertFalse(w.isDay)
        assertNull(Weather.parse("{}"))
        assertNull(Weather.parse("not json"))
        assertTrue(Weather.parse("""{"current":{"temperature_2m":1,"weather_code":0}}""")!!.isDay)
    }
}
