package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CompanionHandlerTest {
    private lateinit var backend: FakeBackend
    private lateinit var pairing: PairingManager
    private lateinit var handler: CompanionHandler
    private var lastLayout: Layout? = null
    private val foreground = mutableListOf<String>()
    private var nextId = 1

    @Before
    fun setUp() {
        backend = FakeBackend()
        pairing = PairingManager(MemoryTokenStore())
        handler = CompanionHandler(backend, pairing, clock = { 42L }, onLayoutChanged = { lastLayout = it }, onForegroundApp = { foreground += it })
    }

    private fun call(type: String, params: JSONObject = JSONObject()): JSONObject {
        val req = JSONObject(params.toString()).put("id", nextId++).put("type", type)
        return JSONObject(handler.handle(req.toString()))
    }

    private fun pair(): String {
        call("pair.request", JSONObject().put("client", "iPhone de Luis"))
        val code = backend.shownCode!!
        return call("pair.confirm", JSONObject().put("code", code)).getJSONObject("data").getString("token")
    }

    @Test
    fun `methods need authentication`() {
        val r = call("apps.list")
        assertEquals("error", r.getString("type"))
        assertEquals("auth_required", r.getString("code"))
        assertEquals("result", call("ping").getString("type"))
    }

    @Test
    fun `pairing shows the code on the TV and hides it after`() {
        val r = call("pair.request", JSONObject().put("client", "iPhone de Luis"))
        assertTrue(r.getJSONObject("data").getBoolean("pending"))
        assertEquals("iPhone de Luis", backend.shownClient)
        val wrong = call("pair.confirm", JSONObject().put("code", "x"))
        assertEquals("bad_code", wrong.getString("code"))
        val ok = call("pair.confirm", JSONObject().put("code", backend.shownCode))
        assertTrue(ok.getJSONObject("data").getString("token").isNotEmpty())
        assertEquals(null, backend.shownCode)
        assertTrue(handler.authenticated)
        assertEquals("iPhone de Luis", handler.clientName)
    }

    @Test
    fun `hello with a stored token authenticates`() {
        val token = pair()
        val fresh = CompanionHandler(backend, pairing)
        val r = JSONObject(fresh.handle(JSONObject().put("id", 1).put("type", "hello").put("token", token).put("client", "iPhone").toString()))
        assertTrue(r.getJSONObject("data").getBoolean("authenticated"))
        assertEquals("Hisense 65U6GA", r.getJSONObject("data").getJSONObject("server").getString("name"))
        val bad = JSONObject(CompanionHandler(backend, pairing).handle("""{"id":1,"type":"hello","token":"nope"}"""))
        assertEquals("auth_required", bad.getString("code"))
    }

    @Test
    fun `apps icons and launching`() {
        pair()
        val apps = call("apps.list").getJSONObject("data").getJSONArray("apps")
        assertEquals(2, apps.length())
        assertEquals("YouTube", apps.getJSONObject(0).getString("label"))
        val icon = call("apps.icon", JSONObject().put("package", "com.netflix.ninja")).getJSONObject("data")
        assertEquals("iVBORw==", icon.getString("png"))
        assertEquals("not_found", call("apps.icon", JSONObject().put("package", "x.y")).getString("code"))
        assertEquals("result", call("apps.launch", JSONObject().put("package", "com.netflix.ninja")).getString("type"))
        assertEquals(listOf("com.netflix.ninja"), backend.launched)
        assertEquals(listOf("com.netflix.ninja"), foreground)
        assertEquals("not_found", call("apps.launch", JSONObject().put("package", "missing.app")).getString("code"))
        assertEquals("bad_request", call("apps.launch").getString("code"))
    }

    @Test
    fun `layout is normalized, saved and announced`() {
        pair()
        val layout = JSONObject().put("order", org.json.JSONArray(listOf("a.b", "a.b", "c.d"))).put("hidden", org.json.JSONArray(listOf("c.d", "e.f"))).put("columns", 20)
        val saved = call("launcher.set", JSONObject().put("layout", layout)).getJSONObject("data").getJSONObject("layout")
        assertEquals(listOf("a.b", "c.d"), saved.getJSONArray("order").strings())
        assertEquals(listOf("e.f"), saved.getJSONArray("hidden").strings())
        assertEquals(Layout.MAX_COLUMNS, saved.getInt("columns"))
        assertEquals(backend.layout, lastLayout)
        assertTrue(saved.similar(call("launcher.get").getJSONObject("data").getJSONObject("layout")))
        assertEquals("bad_request", call("launcher.set").getString("code"))
    }

    @Test
    fun `inputs now playing usage backup`() {
        pair()
        assertEquals("hdmi", call("inputs.list").getJSONObject("data").getJSONArray("inputs").getJSONObject(0).getString("kind"))
        assertEquals("result", call("inputs.open", JSONObject().put("input", "hdmi1")).getString("type"))
        assertEquals("not_found", call("inputs.open", JSONObject().put("input", "x")).getString("code"))
        assertTrue(call("nowPlaying.get").getJSONObject("data").isNull("nowPlaying"))
        backend.playing = NowPlaying("com.netflix.ninja", "Serie", null, "playing", 10, 100)
        assertEquals("Serie", call("nowPlaying.get").getJSONObject("data").getJSONObject("nowPlaying").getString("title"))
        assertEquals(1, call("usage.get", JSONObject().put("days", 99)).getJSONObject("data").getJSONArray("entries").length())
        backend.usageAllowed = false
        assertEquals("unsupported", call("usage.get").getString("code"))
        val backup = call("backup.export").getJSONObject("data").getJSONObject("backup")
        assertEquals(42L, backup.getLong("exportedAt"))
        backup.getJSONObject("layout").put("order", org.json.JSONArray(listOf("z.z")))
        val restored = call("backup.import", JSONObject().put("backup", backup)).getJSONObject("data").getJSONObject("layout")
        assertEquals(listOf("z.z"), restored.getJSONArray("order").strings())
        assertEquals("bad_request", call("backup.import", JSONObject().put("backup", JSONObject().put("version", 9))).getString("code"))
    }

    @Test
    fun `garbage and unknown methods`() {
        assertEquals("bad_request", JSONObject(handler.handle("not json")).getString("code"))
        assertEquals("bad_request", JSONObject(handler.handle("""{"id":"x","type":"ping"}""")).getString("code"))
        pair()
        assertEquals("unsupported", call("teleport").getString("code"))
        assertFalse(JSONObject(handler.handle("""{"type":"ping"}""")).has("id"))
    }
}
