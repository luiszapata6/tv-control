package com.luiszapata.tvcontrol.tv_launcher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Starts the companion service at boot and after an update. App installs and
 * removals are watched at runtime by Launcher (LauncherApps.Callback).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> CompanionService.start(context)
        }
    }
}
