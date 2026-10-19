package com.luiszapata.tvcontrol.tv_launcher.companion

import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap

/**
 * WebSocket server on [Protocol.PORT]. Each connection gets its own
 * [CompanionHandler]; events are broadcast to authenticated clients only.
 */
class CompanionServer(
    port: Int,
    private val handlerFactory: () -> CompanionHandler,
    private val onClientsChanged: (List<String>) -> Unit,
) : WebSocketServer(InetSocketAddress(port)) {
    private val handlers = ConcurrentHashMap<WebSocket, CompanionHandler>()

    init {
        isReuseAddr = true
        connectionLostTimeout = 30
    }

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
        if (handshake.resourceDescriptor?.startsWith(Protocol.PATH) != true) {
            conn.close(1008, "unknown path")
            return
        }
        handlers[conn] = handlerFactory()
    }

    override fun onMessage(conn: WebSocket, message: String) {
        val handler = handlers[conn] ?: return
        val wasAuthed = handler.authenticated
        conn.send(handler.handle(message))
        if (!wasAuthed && handler.authenticated) notifyClients()
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String?, remote: Boolean) {
        val removed = handlers.remove(conn)
        if (removed?.authenticated == true) notifyClients()
    }

    override fun onError(conn: WebSocket?, ex: Exception) {
        // Per-connection errors close that connection; server errors are logged by the library.
    }

    override fun onStart() {}

    fun broadcastEvent(name: String, data: org.json.JSONObject) {
        val frame = Frames.event(name, data)
        for ((conn, h) in handlers) {
            if (h.authenticated && conn.isOpen) conn.send(frame)
        }
    }

    fun clientNames(): List<String> = handlers.values.filter { it.authenticated }.map { it.clientName }.distinct()

    private fun notifyClients() = onClientsChanged(clientNames())
}
