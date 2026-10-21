package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
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
    fun `pair confirm returns the server info`() {
        call("pair.request", JSONObject().put("client", "iPhone"))
        val data = call("pair.confirm", JSONObject().put("code", backend.shownCode)).getJSONObject("data")
        assertEquals("Hisense 65U6GA", data.getJSONObject("server").getString("name"))
        assertEquals("a1b2c3", data.getJSONObject("server").getString("deviceId"))
    }

    private fun request(h: CompanionHandler, type: String, params: JSONObject = JSONObject()): JSONObject =
        JSONObject(h.handle(JSONObject(params.toString()).put("id", nextId++).put("type", type).toString()))

    @Test
    fun `a second device cannot request a code while one is shown`() {
        call("pair.request", JSONObject().put("client", "iPhone de Luis"))
        val shown = backend.shownCode
        val other = CompanionHandler(backend, pairing)
        assertEquals("busy", request(other, "pair.request", JSONObject().put("client", "Intruso")).getString("code"))
        assertEquals("the code on screen is unchanged", shown, backend.shownCode)
        assertEquals("iPhone de Luis", backend.shownClient)
        assertEquals("bad_code", request(other, "pair.confirm", JSONObject().put("code", shown)).getString("code"))
        assertEquals(shown, backend.shownCode)
        assertFalse(other.authenticated)
    }

    @Test
    fun `pair request is refused while locked`() {
        call("pair.request")
        val wrong = if (backend.shownCode == "000000") "111111" else "000000"
        repeat(Protocol.MAX_FAILED_CODES) { call("pair.confirm", JSONObject().put("code", wrong)) }
        assertNull("lock hides the code", backend.shownCode)
        val r = call("pair.request")
        assertEquals("locked", r.getString("code"))
        assertNull(backend.shownCode)
    }

    @Test
    fun `closing the requesting connection hides the code`() {
        call("pair.request", JSONObject().put("client", "iPhone"))
        val other = CompanionHandler(backend, pairing)
        other.onClosed()
        assertTrue("other connections do not hide it", backend.shownCode != null)
        handler.onClosed()
        assertNull(backend.shownCode)
        assertNull(pairing.activeCode())
        assertEquals("result", request(other, "pair.request").getString("type"))
    }

    @Test
    fun `expired code is hidden and cannot be confirmed`() {
        var now = 0L
        val timedPairing = PairingManager(MemoryTokenStore(), clock = { now })
        val h = CompanionHandler(backend, timedPairing, clock = { now })
        request(h, "pair.request")
        val code = backend.shownCode!!
        now += Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertEquals("bad_code", request(h, "pair.confirm", JSONObject().put("code", code)).getString("code"))
        assertNull(backend.shownCode)
        assertFalse(h.authenticated)
    }

    @Test
    fun `unauthenticated connections time out unless waiting on their code`() {
        var now = 0L
        val timedPairing = PairingManager(MemoryTokenStore(), clock = { now })
        val idle = CompanionHandler(backend, timedPairing, clock = { now })
        val pairingOne = CompanionHandler(backend, timedPairing, clock = { now })
        request(pairingOne, "pair.request")
        now = Protocol.UNAUTHENTICATED_TIMEOUT_MS
        assertFalse(idle.isUnauthenticatedTooLong())
        now = Protocol.UNAUTHENTICATED_TIMEOUT_MS + 1
        assertTrue(idle.isUnauthenticatedTooLong())
        assertFalse("its code is still on screen", pairingOne.isUnauthenticatedTooLong())
        now = Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertTrue(pairingOne.isUnauthenticatedTooLong())
        val authed = CompanionHandler(backend, timedPairing, clock = { now })
        request(authed, "pair.request")
        request(authed, "pair.confirm", JSONObject().put("code", backend.shownCode))
        now += Protocol.UNAUTHENTICATED_TIMEOUT_MS * 10
        assertFalse(authed.isUnauthenticatedTooLong())
    }

    @Test
    fun `revoked connections need to pair again`() {
        val token = pair()
        assertEquals("result", call("apps.list").getString("type"))
        pairing.revokeAll()
        handler.revoke()
        assertEquals("auth_required", call("apps.list").getString("code"))
        val fresh = CompanionHandler(backend, pairing)
        assertEquals("auth_required", request(fresh, "hello", JSONObject().put("token", token)).getString("code"))
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
        assertTrue(jsonEquals(saved, call("launcher.get").getJSONObject("data").getJSONObject("layout")))
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
