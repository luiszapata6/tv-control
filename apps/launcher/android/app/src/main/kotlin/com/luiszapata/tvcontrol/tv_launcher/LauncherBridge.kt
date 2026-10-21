package com.luiszapata.tvcontrol.tv_launcher

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import com.luiszapata.tvcontrol.tv_launcher.companion.Protocol
import com.luiszapata.tvcontrol.tv_launcher.core.EventBus
import com.luiszapata.tvcontrol.tv_launcher.core.Launcher
import com.luiszapata.tvcontrol.tv_launcher.core.LauncherEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.concurrent.Executors

/** MethodChannel `tvcontrol/launcher` + EventChannel `tvcontrol/events` for the Flutter UI. */
class LauncherBridge(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val io = Executors.newSingleThreadExecutor()
    private val method = MethodChannel(messenger, "tvcontrol/launcher")
    private val events = EventChannel(messenger, "tvcontrol/events")
    private var unsubscribe: (() -> Unit)? = null

    init {
        method.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                unsubscribe = EventBus.subscribe { e -> toMap(e)?.let(sink::success) }
            }

            override fun onCancel(arguments: Any?) {
                unsubscribe?.invoke()
                unsubscribe = null
            }
        })
    }

    fun dispose() {
        unsubscribe?.invoke()
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
        io.shutdown()
    }

    private fun toMap(e: LauncherEvent): Map<String, Any?>? = when (e) {
        LauncherEvent.AppsChanged -> mapOf("type" to "appsChanged")
        is LauncherEvent.LayoutChanged -> mapOf("type" to "layoutChanged", "layout" to jsonToMap(JSONObject(e.layoutJson)))
        is LauncherEvent.PairingCode -> mapOf("type" to "pairingCode", "code" to e.code, "client" to e.client)
        is LauncherEvent.Clients -> mapOf("type" to "clients", "names" to e.names)
        else -> null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Package manager and bitmap work stays off the main thread.
        io.execute {
            val reply = try {
                Result.success(handle(call))
            } catch (e: Exception) {
                Result.failure(e)
            }
            android.os.Handler(context.mainLooper).post {
                reply.fold(
                    onSuccess = { if (it === NOT_IMPLEMENTED) result.notImplemented() else result.success(it) },
                    onFailure = { result.error("native", it.message, null) },
                )
            }
        }
    }

    private fun handle(call: MethodCall): Any? = when (call.method) {
        "apps" -> Launcher.apps.apps().map {
            mapOf("package" to it.packageName, "label" to it.label, "isSystem" to it.isSystem)
        }
        "icon" -> Launcher.apps.iconPng(call.argument<String>("package")!!)
        "launch" -> {
            val pkg = call.argument<String>("package")!!
            Launcher.apps.launch(pkg).also { if (it) EventBus.post(LauncherEvent.ForegroundApp(pkg)) }
        }
        "layout" -> jsonToMap(Launcher.layouts.get().toJson())
        "setLayout" -> {
            @Suppress("UNCHECKED_CAST")
            val raw = call.argument<Map<String, Any?>>("layout")!!
            jsonToMap(Launcher.layouts.set(Layout.fromJson(JSONObject(raw))).toJson())
        }
        "inputs" -> Launcher.inputsRepo.inputs().map { mapOf("id" to it.id, "label" to it.label, "kind" to it.kind) }
        "openInput" -> Launcher.inputsRepo.open(call.argument<String>("id")!!)
        "openSettings" -> start(Intent(Settings.ACTION_SETTINGS))
        "openAppInfo" -> start(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + call.argument<String>("package"))),
        )
        "revokeDevices" -> {
            Launcher.revokeAll()
            true
        }
        "companionAddress" -> localIp()?.let { "$it:${Protocol.PORT}" } ?: ""
        else -> NOT_IMPLEMENTED
    }

    private fun start(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (e: Exception) {
        false
    }

    private fun localIp(): String? = NetworkInterface.getNetworkInterfaces().toList()
        .filter { it.isUp && !it.isLoopback }
        .flatMap { it.inetAddresses.toList() }
        .firstOrNull { it is Inet4Address }
        ?.hostAddress

    companion object {
        private val NOT_IMPLEMENTED = Any()

        fun jsonToMap(j: JSONObject): Map<String, Any?> = j.keys().asSequence().associateWith { k -> unwrap(j.get(k)) }

        private fun unwrap(v: Any?): Any? = when (v) {
            is JSONObject -> jsonToMap(v)
            is JSONArray -> (0 until v.length()).map { unwrap(v.get(it)) }
            JSONObject.NULL -> null
            else -> v
        }
    }
}
