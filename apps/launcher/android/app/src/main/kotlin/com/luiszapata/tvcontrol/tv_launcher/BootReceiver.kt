package com.luiszapata.tvcontrol.tv_launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.luiszapata.tvcontrol.tv_launcher.core.EventBus
import com.luiszapata.tvcontrol.tv_launcher.core.Launcher
import com.luiszapata.tvcontrol.tv_launcher.core.LauncherEvent

/** Starts the companion service at boot and tracks app installs/removals. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> CompanionService.start(context)
            Intent.ACTION_PACKAGE_ADDED, Intent.ACTION_PACKAGE_REMOVED, Intent.ACTION_PACKAGE_REPLACED -> {
                Launcher.init(context)
                Launcher.apps.clearIcons()
                EventBus.post(LauncherEvent.AppsChanged)
            }
        }
    }
}
