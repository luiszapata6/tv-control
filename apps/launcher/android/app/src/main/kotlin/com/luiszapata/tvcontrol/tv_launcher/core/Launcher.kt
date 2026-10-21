package com.luiszapata.tvcontrol.tv_launcher.core

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.LauncherApps
import android.os.Handler
import android.os.Looper
import android.os.UserHandle
import android.provider.Settings
import com.luiszapata.tvcontrol.tv_launcher.companion.AppInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.CompanionBackend
import com.luiszapata.tvcontrol.tv_launcher.companion.InputInfo
import com.luiszapata.tvcontrol.tv_launcher.companion.Layout
import com.luiszapata.tvcontrol.tv_launcher.companion.NowPlaying
import com.luiszapata.tvcontrol.tv_launcher.companion.PairingManager
import com.luiszapata.tvcontrol.tv_launcher.companion.TokenStore
import com.luiszapata.tvcontrol.tv_launcher.companion.UsageEntry

/** Process-wide services shared by the Flutter bridge and the companion service. */
@SuppressLint("StaticFieldLeak") // holds the application context only
object Launcher : CompanionBackend {
    private lateinit var context: Context
    lateinit var apps: AppRepository
        private set
    lateinit var layouts: LayoutStore
        private set
    lateinit var inputsRepo: InputsRepository
        private set
    lateinit var usageRepo: UsageRepository
        private set
    lateinit var nowPlayingTracker: NowPlayingTracker
        private set
    lateinit var pairing: PairingManager
        private set

    @Synchronized
    fun init(appContext: Context) {
        if (::context.isInitialized) return
        context = appContext.applicationContext
        apps = AppRepository(context)
        layouts = LayoutStore(context)
        inputsRepo = InputsRepository(context)
        usageRepo = UsageRepository(context) { pkg -> apps.apps().firstOrNull { it.packageName == pkg }?.label ?: pkg }
        nowPlayingTracker = NowPlayingTracker(context).also { it.start() }
        pairing = PairingManager(PrefsTokenStore(context))
        watchPackages()
    }

    private val main = Handler(Looper.getMainLooper())
    private val appsChanged = Runnable {
        apps.clearIcons()
        EventBus.post(LauncherEvent.AppsChanged)
    }

    /**
     * Manifest receivers no longer get PACKAGE_ADDED/REMOVED/REPLACED (API 26+),
     * so installs and removals are watched at runtime while the process lives.
     */
    private fun watchPackages() {
        val launcherApps = context.getSystemService(LauncherApps::class.java) ?: return
        val callback = object : LauncherApps.Callback() {
            override fun onPackageAdded(packageName: String?, user: UserHandle?) = changed()
            override fun onPackageRemoved(packageName: String?, user: UserHandle?) = changed()
            override fun onPackageChanged(packageName: String?, user: UserHandle?) = changed()
            override fun onPackagesAvailable(packageNames: Array<out String>?, user: UserHandle?, replacing: Boolean) = changed()
            override fun onPackagesUnavailable(packageNames: Array<out String>?, user: UserHandle?, replacing: Boolean) = changed()
        }
        try {
            launcherApps.registerCallback(callback, main)
        } catch (e: Exception) {
            android.util.Log.w("Launcher", "cannot watch package changes", e)
        }
    }

    /** Debounced: an update fires several callbacks. */
    private fun changed() {
        main.removeCallbacks(appsChanged)
        main.postDelayed(appsChanged, 500)
    }

    /** Forgets every paired iPhone and disconnects the ones connected now. */
    fun revokeAll() {
        pairing.revokeAll()
        EventBus.post(LauncherEvent.DevicesRevoked)
    }

    override val tvName: String
        get() = Settings.Global.getString(context.contentResolver, "device_name")
            ?: android.os.Build.MODEL ?: "Android TV"

    @get:SuppressLint("HardwareIds")
    override val deviceId: String
        get() = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"

    override fun apps(): List<AppInfo> = apps.apps()
    override fun iconPng(packageName: String): ByteArray? = apps.iconPng(packageName)
    override fun launch(packageName: String): Boolean = apps.launch(packageName)
    override fun layout(): Layout = layouts.get()
    override fun setLayout(layout: Layout): Layout = layouts.set(layout)
    override fun inputs(): List<InputInfo> = inputsRepo.inputs()
    override fun openInput(id: String): Boolean = inputsRepo.open(id)
    override fun nowPlaying(): NowPlaying? = nowPlayingTracker.current()
    override fun usage(days: Int): Pair<Long, List<UsageEntry>>? = usageRepo.usage(days)

    override fun showPairingCode(code: String?, client: String?) {
        EventBus.post(LauncherEvent.PairingCode(code, client))
    }
}

/** SHA-256 hashes of the pairing tokens. */
private class PrefsTokenStore(context: Context) : TokenStore {
    private val prefs = context.getSharedPreferences("companion", Context.MODE_PRIVATE)

    init {
        // Older builds kept plaintext tokens: drop them (those iPhones pair again).
        if (prefs.contains(LEGACY_KEY)) prefs.edit().remove(LEGACY_KEY).apply()
    }

    override fun tokenHashes(): Set<String> = prefs.getStringSet(KEY, emptySet()).orEmpty().toSet()
    override fun save(tokenHashes: Set<String>) {
        prefs.edit().putStringSet(KEY, tokenHashes).apply()
    }

    private companion object {
        const val KEY = "token_hashes"
        const val LEGACY_KEY = "tokens"
    }
}
