package com.luiszapata.tvcontrol.tv_launcher.companion

class FakeBackend : CompanionBackend {
    override val tvName = "Hisense 65U6GA"
    override val deviceId = "a1b2c3"
    var layout = Layout(order = listOf("com.google.android.youtube.tv"))
    val launched = mutableListOf<String>()
    val opened = mutableListOf<String>()
    var shownCode: String? = null
    var shownClient: String? = null
    var usageAllowed = true
    var playing: NowPlaying? = null

    override fun apps() = listOf(
        AppInfo("com.google.android.youtube.tv", "YouTube", 3, false),
        AppInfo("com.netflix.ninja", "Netflix", 9, false),
    )

    override fun iconPng(packageName: String) =
        if (packageName == "com.netflix.ninja") byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47) else null

    override fun launch(packageName: String): Boolean {
        if (apps().none { it.packageName == packageName }) return false
        launched += packageName
        return true
    }

    override fun layout() = layout
    override fun setLayout(layout: Layout): Layout {
        this.layout = layout.normalized()
        return this.layout
    }

    override fun inputs() = listOf(InputInfo("hdmi1", "HDMI 1", "hdmi"))
    override fun openInput(id: String) = (id == "hdmi1").also { if (it) opened += id }
    override fun nowPlaying() = playing
    override fun usage(days: Int) =
        if (usageAllowed) 1000L to listOf(UsageEntry("com.netflix.ninja", "Netflix", 3_600_000)) else null

    override fun showPairingCode(code: String?, client: String?) {
        shownCode = code
        shownClient = client
    }
}
