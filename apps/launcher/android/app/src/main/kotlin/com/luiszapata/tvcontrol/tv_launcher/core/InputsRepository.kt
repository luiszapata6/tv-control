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

    fun inputs(): List<InputInfo> {
        val list = try {
            manager?.tvInputList.orEmpty()
        } catch (e: SecurityException) {
            emptyList()
        }
        var hdmiIndex = 0
        return list.filter { it.parentId == null || it.type == TvInputInfo.TYPE_HDMI }
            .sortedBy { it.id }
            .map { info ->
                val kind = when (info.type) {
                    TvInputInfo.TYPE_HDMI -> "hdmi"
                    TvInputInfo.TYPE_TUNER -> "tuner"
                    else -> "other"
                }
                val custom = info.loadCustomLabel(context)?.toString()
                val label = custom?.takeIf { it.isNotBlank() }
                    ?: if (kind == "hdmi") "HDMI ${++hdmiIndex}" else info.loadLabel(context).toString()
                InputInfo(info.id, label, kind)
            }
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
