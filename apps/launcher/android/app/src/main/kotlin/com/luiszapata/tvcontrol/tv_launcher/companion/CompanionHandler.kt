package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONArray
import org.json.JSONObject
import java.util.Base64

/**
 * Protocol logic for one client connection. Pure Kotlin so it is unit tested
 * on the JVM: feed it text frames with [handle], send back what it returns.
 */
class CompanionHandler(
    private val backend: CompanionBackend,
    private val pairing: PairingManager,
    private val clock: () -> Long = System::currentTimeMillis,
    /** Called with the new layout after a successful launcher.set/backup.import. */
    private val onLayoutChanged: (Layout) -> Unit = {},
    private val onForegroundApp: (String) -> Unit = {},
) {
    var authenticated = false
        private set
    var clientName: String = "iPhone"
        private set

    fun handle(text: String): String {
        val req = Frames.parseRequest(text) ?: return Frames.error(null, Protocol.Error.BAD_REQUEST, "malformed frame")
        if (!authenticated && req.method !in Protocol.Method.PUBLIC) {
            return Frames.error(req.id, Protocol.Error.AUTH_REQUIRED, "pair first")
        }
        val id = req.id ?: return Frames.error(null, Protocol.Error.BAD_REQUEST, "missing id")
        return try {
            dispatch(id, req)
        } catch (e: BadRequest) {
            Frames.error(id, Protocol.Error.BAD_REQUEST, e.message ?: "bad request")
        } catch (e: Exception) {
            Frames.error(id, Protocol.Error.INTERNAL, e.javaClass.simpleName + ": " + (e.message ?: ""))
        }
    }

    private class BadRequest(message: String) : Exception(message)

    private fun JSONObject.requireString(key: String): String {
        val v = opt(key)
        if (v !is String || v.isEmpty()) throw BadRequest("missing $key")
        return v
    }

    private fun dispatch(id: Int, req: Request): String {
        val p = req.params
        return when (req.method) {
            Protocol.Method.HELLO -> {
                clientName = (p.opt("client") as? String)?.take(60)?.ifBlank { null } ?: clientName
                if (pairing.isValidToken(p.opt("token") as? String)) {
                    authenticated = true
                    Frames.result(id, JSONObject().put("authenticated", true).put("server", serverInfo()))
                } else {
                    Frames.error(id, Protocol.Error.AUTH_REQUIRED, "pair first")
                }
            }
            Protocol.Method.PAIR_REQUEST -> {
                clientName = (p.opt("client") as? String)?.take(60)?.ifBlank { null } ?: clientName
                val code = pairing.requestCode(clientName)
                backend.showPairingCode(code, clientName)
                Frames.result(id, JSONObject().put("pending", true))
            }
            Protocol.Method.PAIR_CONFIRM -> when (val r = pairing.confirm(p.requireString("code"))) {
                is PairingManager.ConfirmResult.Ok -> {
                    authenticated = true
                    backend.showPairingCode(null, null)
                    Frames.result(id, JSONObject().put("token", r.token).put("server", serverInfo()))
                }
                is PairingManager.ConfirmResult.BadCode ->
                    Frames.error(id, Protocol.Error.BAD_CODE, "wrong code, ${r.attemptsLeft} attempts left")
                is PairingManager.ConfirmResult.Locked -> {
                    backend.showPairingCode(null, null)
                    Frames.error(id, Protocol.Error.LOCKED, "try again in ${r.secondsLeft} s")
                }
                PairingManager.ConfirmResult.NoPendingCode ->
                    Frames.error(id, Protocol.Error.BAD_CODE, "request a new code")
            }
            Protocol.Method.PING -> Frames.result(id, JSONObject().put("time", clock()))
            Protocol.Method.APPS_LIST ->
                Frames.result(id, JSONObject().put("apps", JSONArray(backend.apps().map { it.toJson() })))
            Protocol.Method.APPS_ICON -> {
                val pkg = p.requireString("package")
                val png = backend.iconPng(pkg) ?: return Frames.error(id, Protocol.Error.NOT_FOUND, "no icon for $pkg")
                Frames.result(id, JSONObject().put("package", pkg).put("png", Base64.getEncoder().encodeToString(png)))
            }
            Protocol.Method.APPS_LAUNCH -> {
                val pkg = p.requireString("package")
                if (backend.launch(pkg)) {
                    onForegroundApp(pkg)
                    Frames.result(id)
                } else {
                    Frames.error(id, Protocol.Error.NOT_FOUND, "app not installed")
                }
            }
            Protocol.Method.LAUNCHER_GET -> Frames.result(id, JSONObject().put("layout", backend.layout().toJson()))
            Protocol.Method.LAUNCHER_SET -> {
                val layout = p.optJSONObject("layout") ?: throw BadRequest("missing layout")
                val saved = backend.setLayout(Layout.fromJson(layout))
                onLayoutChanged(saved)
                Frames.result(id, JSONObject().put("layout", saved.toJson()))
            }
            Protocol.Method.INPUTS_LIST ->
                Frames.result(id, JSONObject().put("inputs", JSONArray(backend.inputs().map { it.toJson() })))
            Protocol.Method.INPUTS_OPEN -> {
                val input = p.requireString("input")
                if (backend.openInput(input)) Frames.result(id) else Frames.error(id, Protocol.Error.NOT_FOUND, "unknown input")
            }
            Protocol.Method.NOW_PLAYING_GET ->
                Frames.result(id, JSONObject().put("nowPlaying", backend.nowPlaying()?.toJson() ?: JSONObject.NULL))
            Protocol.Method.USAGE_GET -> {
                val days = p.optInt("days", 7).coerceIn(1, 30)
                val (since, entries) = backend.usage(days)
                    ?: return Frames.error(id, Protocol.Error.UNSUPPORTED, "usage access not granted")
                Frames.result(id, JSONObject().put("since", since).put("entries", JSONArray(entries.map { it.toJson() })))
            }
            Protocol.Method.BACKUP_EXPORT -> Frames.result(
                id,
                JSONObject().put(
                    "backup",
                    JSONObject().put("version", 1).put("layout", backend.layout().toJson()).put("exportedAt", clock()),
                ),
            )
            Protocol.Method.BACKUP_IMPORT -> {
                val backup = p.optJSONObject("backup") ?: throw BadRequest("missing backup")
                if (backup.optInt("version", 1) != 1) throw BadRequest("unsupported backup version")
                val saved = backend.setLayout(Layout.fromJson(backup.optJSONObject("layout")))
                onLayoutChanged(saved)
                Frames.result(id, JSONObject().put("layout", saved.toJson()))
            }
            else -> Frames.error(id, Protocol.Error.UNSUPPORTED, req.method)
        }
    }

    private fun serverInfo(): JSONObject =
        JSONObject().put("name", backend.tvName).put("version", Protocol.VERSION).put("deviceId", backend.deviceId)
}
