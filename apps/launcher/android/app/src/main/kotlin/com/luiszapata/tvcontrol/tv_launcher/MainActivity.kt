package com.luiszapata.tvcontrol.tv_launcher

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.InputInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import com.luiszapata.tvcontrol.tv_launcher.companion.Protocol
import com.luiszapata.tvcontrol.tv_launcher.core.EventBus
import com.luiszapata.tvcontrol.tv_launcher.core.Launcher
import com.luiszapata.tvcontrol.tv_launcher.core.LauncherEvent
import com.luiszapata.tvcontrol.tv_launcher.core.Weather
import com.luiszapata.tvcontrol.tv_launcher.ui.Art
import com.luiszapata.tvcontrol.tv_launcher.ui.C
import com.luiszapata.tvcontrol.tv_launcher.ui.FocusFrame
import com.luiszapata.tvcontrol.tv_launcher.ui.HomeScreen
import com.luiszapata.tvcontrol.tv_launcher.ui.Overlays
import com.luiszapata.tvcontrol.tv_launcher.ui.Ui
import org.json.JSONObject
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.concurrent.Executors

/** The home screen: native views (fast on weak TV GPUs), state from [Launcher]. */
class MainActivity : Activity() {
    lateinit var ui: Ui
    private lateinit var root: FrameLayout
    private lateinit var home: HomeScreen
    private val overlays = ArrayList<View>()
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var unsubscribe: (() -> Unit)? = null

    var apps: List<AppInfo> = emptyList(); private set
    var layout: Layout = Layout(); private set
    var inputs: List<InputInfo> = emptyList(); private set
    var clients: List<String> = emptyList(); private set
    /** When each app was last used ("Seguir viendo"). */
    var lastUsed: Map<String, Long> = emptyMap(); private set
    var loaded = false; private set
    private var pairing: View? = null

    private val weatherLoop = object : Runnable {
        override fun run() {
            io.execute { Weather.fetch()?.let { w -> main.post { home.setWeather(w) } } }
            main.postDelayed(this, 20 * 60 * 1000L)
        }
    }

    private val tick = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = home.tick()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Launcher.init(this)
        ui = Ui(this)
        root = FrameLayout(this).apply { setBackgroundColor(C.HOME_BG) }
        home = HomeScreen(this)
        root.addView(home.view)
        setContentView(root)
        unsubscribe = EventBus.subscribe(::onEvent)
        reload()
        main.post(weatherLoop)
    }

    override fun onStart() {
        super.onStart()
        registerReceiver(tick, IntentFilter().apply {
            addAction(Intent.ACTION_TIME_TICK)
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
        })
        home.tick()
    }

    override fun onStop() {
        unregisterReceiver(tick)
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        // Notification access may have been granted while we were away.
        Launcher.nowPlayingTracker.start()
        if (!CompanionService.running) CompanionService.start(this)
        // Back from an app: "Seguir viendo" changed.
        if (loaded) io.execute { Launcher.usageRepo.lastUsed().let { u -> main.post { if (u != lastUsed) { lastUsed = u; home.render() } } } }
        // A pairing request may have arrived while this screen was not running.
        if (pairing == null) Launcher.pairing.activeCode()?.let { showPairing(it, Launcher.pairing.requestedBy) }
    }

    override fun onDestroy() {
        unsubscribe?.invoke()
        main.removeCallbacksAndMessages(null)
        io.shutdown()
        super.onDestroy()
    }

    /** Home pressed while already home: close whatever is open. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        while (overlays.isNotEmpty() && overlays.last() !== pairing) pop()
        if (overlays.isEmpty()) home.focusFirst()
    }

    // ------------------------------------------------------------------ data

    private fun reload() = io.execute {
        val a = Launcher.apps.apps()
        val l = Launcher.layouts.get()
        val i = try { Launcher.inputsRepo.inputs() } catch (e: Exception) { emptyList() }
        val u = Launcher.usageRepo.lastUsed()
        main.post {
            apps = a; layout = l; inputs = i; lastUsed = u; loaded = true
            home.render()
        }
    }

    /** Shows [next] right away and saves it; the store notifies the iPhone. */
    fun saveLayout(next: Layout) {
        if (next == layout) return
        layout = next
        home.render()
        io.execute { Launcher.layouts.set(next) }
    }

    private fun onEvent(e: LauncherEvent) {
        when (e) {
            LauncherEvent.AppsChanged -> { Art.clear(); reload() }
            is LauncherEvent.LayoutChanged -> {
                val l = Layout.fromJson(JSONObject(e.layoutJson))
                if (l != layout) { layout = l; home.render() }
            }
            is LauncherEvent.PairingCode -> showPairing(e.code, e.client)
            is LauncherEvent.Clients -> { clients = e.names; home.renderFooter() }
            else -> Unit
        }
    }

    private fun showPairing(code: String?, client: String?) {
        pairing?.let { remove(it) }
        pairing = code?.let { Overlays.pairing(this, it, client).also(::push) }
    }

    // --------------------------------------------------------------- actions

    fun launch(pkg: String) {
        if (Launcher.apps.launch(pkg)) EventBus.post(LauncherEvent.ForegroundApp(pkg))
    }

    /**
     * Ends an app left in the background and frees its memory (Android TV has
     * no recents screen to swipe it away). Only background processes: never
     * the app on screen.
     */
    fun closeApp(pkg: String) {
        (getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager).killBackgroundProcesses(pkg)
    }

    fun openInput(id: String) = io.execute { Launcher.inputsRepo.open(id) }

    fun openSystemSettings() = start(Intent(Settings.ACTION_SETTINGS))

    fun openAppInfo(pkg: String) = start(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg")))

    fun revokeDevices() {
        Launcher.revokeAll()
        clients = emptyList()
        home.renderFooter()
    }

    fun companionAddress(): String = try {
        NetworkInterface.getNetworkInterfaces().toList().filter { it.isUp && !it.isLoopback }
            .flatMap { it.inetAddresses.toList() }.firstOrNull { it is Inet4Address }?.hostAddress
            ?.let { "$it:${Protocol.PORT}" } ?: ""
    } catch (e: Exception) {
        ""
    }

    private fun start(intent: Intent) {
        try {
            startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (e: Exception) {
            // Some TVs hide these screens.
        }
    }

    // -------------------------------------------------------------- overlays

    /** Opens [v] above everything; focus stays inside it until it closes. */
    fun push(v: View) {
        (overlays.lastOrNull() ?: home.view).let { (it as? ViewGroup)?.descendantFocusability = ViewGroup.FOCUS_BLOCK_DESCENDANTS }
        overlays.add(v)
        root.addView(v, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        v.post { if (!v.hasFocus()) v.requestFocus() }
    }

    fun pop() = overlays.lastOrNull()?.let { if (it === pairing) pairing = null; remove(it) }

    private fun remove(v: View) {
        overlays.remove(v)
        root.removeView(v)
        val top = overlays.lastOrNull() ?: home.view
        (top as? ViewGroup)?.descendantFocusability = ViewGroup.FOCUS_AFTER_DESCENDANTS
        if (overlays.isEmpty()) home.restoreFocus() else top.requestFocus()
    }

    fun isTop(v: View) = overlays.lastOrNull() === v

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_BACK || event.keyCode == KeyEvent.KEYCODE_ESCAPE) {
            // A launcher never exits: Back only closes what is open.
            if (event.action == KeyEvent.ACTION_UP && overlays.isNotEmpty()) pop()
            return true
        }
        if (event.keyCode == KeyEvent.KEYCODE_MENU && event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            (currentFocus as? FocusFrame)?.onLongPress?.let { it(); return true }
        }
        return super.dispatchKeyEvent(event)
    }
}
