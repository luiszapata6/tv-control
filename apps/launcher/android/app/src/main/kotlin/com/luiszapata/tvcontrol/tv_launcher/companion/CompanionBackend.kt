package com.luiszapata.tvcontrol.tv_launcher.companion

/** What the companion service can do on the TV. Implemented with Android APIs; faked in tests. */
interface CompanionBackend {
    val tvName: String
    val deviceId: String

    fun apps(): List<AppInfo>

    /** PNG bytes of the app's icon (TV banner preferred), or null if unknown. */
    fun iconPng(packageName: String): ByteArray?

    /** False if the app is not installed or cannot be opened. */
    fun launch(packageName: String): Boolean

    fun layout(): Layout
    fun setLayout(layout: Layout): Layout

    fun inputs(): List<InputInfo>
    fun openInput(id: String): Boolean

    /** Null when nothing is playing or the notification listener permission is missing. */
    fun nowPlaying(): NowPlaying?

    /** Null when the usage access permission is missing. */
    fun usage(days: Int): Pair<Long, List<UsageEntry>>?

    /** Shows or hides (null) the pairing code on the TV. */
    fun showPairingCode(code: String?, client: String?)
}
