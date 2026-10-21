package com.luiszapata.tvcontrol.tv_launcher.core

import android.content.Context
import android.content.Intent
import android.media.tv.TvContract
import android.media.tv.TvInputInfo
import android.media.tv.TvInputManager
import com.luiszapata.tvcontrol.tv_launcher.companion.InputInfo

/** HDMI and tuner inputs from TvInputManager. Hisense may restrict access; then the list is empty. */
class InputsRepository(private val context: Context) {
    private val manager = context.getSystemService(Context.TV_INPUT_SERVICE) as? TvInputManager

    /**
     * HDMI ports in order, each with the name of the device on it when HDMI-CEC
     * reports one (a CEC device is its own input whose parent is the port; it
     * must not be counted as another port), then tuners and others.
     */
    fun inputs(): List<InputInfo> {
        val list = try {
            manager?.tvInputList.orEmpty()
        } catch (e: SecurityException) {
            emptyList()
        }
        val devices = list.filter { it.parentId != null }.associateBy { it.parentId }
        val roots = list.filter { it.parentId == null }
        val hdmi = roots.filter { it.type == TvInputInfo.TYPE_HDMI }.sortedBy { it.id }.mapIndexed { i, info ->
            val custom = info.loadCustomLabel(context)?.toString()?.takeIf { it.isNotBlank() }
            val device = devices[info.id]?.loadLabel(context)?.toString()?.takeIf { it.isNotBlank() }
            InputInfo(info.id, custom ?: "HDMI ${i + 1}", "hdmi", device)
        }
        val others = roots.filter { it.type != TvInputInfo.TYPE_HDMI }.sortedBy { it.id }.map { info ->
            InputInfo(info.id, info.loadLabel(context).toString(), if (info.type == TvInputInfo.TYPE_TUNER) "tuner" else "other")
        }
        return hdmi + others
    }

    fun open(id: String): Boolean {
        val uri = TvContract.buildChannelUriForPassthroughInput(id)
        val intent = Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
