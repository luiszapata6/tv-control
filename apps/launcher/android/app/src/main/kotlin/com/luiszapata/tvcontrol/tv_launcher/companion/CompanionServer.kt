package com.luiszapata.tvcontrol.tv_launcher.companion

import org.java_websocket.WebSocket
import org.java_websocket.drafts.Draft
import org.java_websocket.drafts.Draft_6455
import org.java_websocket.extensions.IExtension
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.protocols.IProtocol
import org.java_websocket.server.WebSocketServer
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap
import org.java_websocket.protocols.Protocol as WsProtocol

/**
 * WebSocket server on [Protocol.PORT]. Each connection gets its own
 * [CompanionHandler]; events are broadcast to authenticated clients only.
 *
 * [start] is asynchronous: [onStarted] runs once the socket is bound and
 * [onFailed] if binding (or the server loop) fails. A failed server cannot be
 * restarted; create a new one. Callbacks run on the server thread.
 */
class CompanionServer(
    port: Int,
    private val handlerFactory: () -> CompanionHandler,
    private val onClientsChanged: (List<String>) -> Unit,
    private val onStarted: (CompanionServer) -> Unit = {},
    private val onFailed: (CompanionServer, Exception) -> Unit = { _, _ -> },
    /** Called on every [sweep], e.g. to expire the pairing code. */
    private val onSweep: () -> Unit = {},
) : WebSocketServer(InetSocketAddress(port), listOf<Draft>(limitedDraft())) {
    private val handlers = ConcurrentHashMap<WebSocket, CompanionHandler>()

    @Volatile
    var started = false
        private set

    @Volatile
    var failed = false
        private set

    init {
        isReuseAddr = true
        connectionLostTimeout = 30
    }

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
        if (!Protocol.isProtocolPath(handshake.resourceDescriptor)) {
            conn.close(Protocol.Close.POLICY, "unknown path")
            return
        }
        if (handlers.size >= Protocol.MAX_CONNECTIONS) {
            conn.close(Protocol.Close.TRY_AGAIN_LATER, "too many connections")
            return
        }
        handlers[conn] = handlerFactory()
    }

    override fun onMessage(conn: WebSocket, message: String) {
        val handler = handlers[conn] ?: return
        // The draft already limits frames to MAX_FRAME_BYTES; this also covers fragmented messages.
        if (message.length > Protocol.MAX_FRAME_BYTES) {
            conn.close(Protocol.Close.TOO_BIG, "frame too large")
            return
        }
        val wasAuthed = handler.authenticated
        conn.send(handler.handle(message))
        if (!wasAuthed && handler.authenticated) notifyClients()
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String?, remote: Boolean) {
        val removed = handlers.remove(conn) ?: return
        removed.onClosed()
        if (removed.authenticated) notifyClients()
    }

    override fun onError(conn: WebSocket?, ex: Exception) {
        // Per-connection errors close that connection. A null connection means the
        // server itself failed (e.g. the port could not be bound) and has stopped.
        if (conn == null) {
            started = false
            failed = true
            onFailed(this, ex)
        }
    }

    override fun onStart() {
        started = true
        onStarted(this)
    }

    /** Runs periodic housekeeping: closes connections that did not authenticate in time. */
    fun sweep() {
        onSweep()
        for ((conn, h) in handlers) {
            if (h.isUnauthenticatedTooLong()) conn.close(Protocol.Close.POLICY, "authentication timeout")
        }
    }

    /** Closes every authenticated connection (pairings were revoked on the TV). */
    fun closeAuthenticated() {
        for ((conn, h) in handlers) {
            if (h.authenticated) {
                h.revoke()
                conn.close(Protocol.Close.REVOKED, "pairing revoked")
            }
        }
        notifyClients()
    }

    fun broadcastEvent(name: String, data: org.json.JSONObject) {
        val frame = Frames.event(name, data)
        for ((conn, h) in handlers) {
            if (h.authenticated && conn.isOpen) conn.send(frame)
        }
    }

    fun clientNames(): List<String> = handlers.values.filter { it.authenticated }.map { it.clientName }.distinct()

    private fun notifyClients() = onClientsChanged(clientNames())

    private companion object {
        /** RFC 6455 draft whose frames larger than [Protocol.MAX_FRAME_BYTES] close the connection (1009). */
        fun limitedDraft(): Draft = Draft_6455(
            emptyList<IExtension>(),
            listOf<IProtocol>(WsProtocol("")),
            Protocol.MAX_FRAME_BYTES,
        )
    }
}
