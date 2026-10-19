package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Contract test: every request in packages/companion_protocol/fixtures/messages.json
 * (the Dart client's fixtures) parses here, and the models encode the same JSON.
 */
class FixturesTest {
    private val fixtures: JSONObject = JSONObject(
        javaClass.classLoader!!.getResource("messages.json")!!.readText(),
    )

    private fun frame(name: String): JSONObject = fixtures.getJSONObject(name)

    private fun assertSimilar(expected: JSONObject, actual: JSONObject) =
        assertTrue("expected $expected\nactual   $actual", expected.similar(actual))

    @Test
    fun `all request fixtures parse`() {
        for (name in fixtures.keys()) {
            val f = frame(name)
            val type = f.getString("type")
            if (type in setOf("result", "error", "event")) continue
            val req = Frames.parseRequest(f.toString())
            assertNotNull(name, req)
            assertEquals(name, type, req!!.method)
            assertEquals(name, f.optInt("id"), req.id)
        }
    }

    @Test
    fun `models encode like the fixtures`() {
        val layoutJson = frame("launcher_result").getJSONObject("data").getJSONObject("layout")
        assertSimilar(layoutJson, Layout.fromJson(layoutJson).toJson())
        val np = frame("now_playing_result").getJSONObject("data").getJSONObject("nowPlaying")
        val model = NowPlaying(
            np.getString("package"), np.getString("title"), np.getString("subtitle"),
            np.getString("state"), np.getLong("positionMs"), np.getLong("durationMs"),
        )
        assertSimilar(np, model.toJson())
        val app = frame("apps_list_result").getJSONObject("data").getJSONArray("apps").getJSONObject(0)
        assertSimilar(app, AppInfo(app.getString("package"), app.getString("label"), app.getLong("versionCode"), app.getBoolean("isSystem")).toJson())
    }

    @Test
    fun `server frames have the fixture shape`() {
        assertSimilar(frame("pair_pending"), JSONObject(Frames.result(2, JSONObject().put("pending", true))))
        assertSimilar(frame("bad_code"), JSONObject(Frames.error(3, "bad_code", "wrong code, 4 attempts left")))
        assertSimilar(frame("event_apps_changed"), JSONObject(Frames.event("appsChanged")))
    }
}
