package com.luiszapata.tvcontrol.tv_launcher.core

import android.annotation.SuppressLint
import android.content.Context
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

private class PrefsTokenStore(context: Context) : TokenStore {
    private val prefs = context.getSharedPreferences("companion", Context.MODE_PRIVATE)
    override fun tokens(): Set<String> = prefs.getStringSet("tokens", emptySet()).orEmpty().toSet()
    override fun save(tokens: Set<String>) {
        prefs.edit().putStringSet("tokens", tokens).apply()
    }
}
