package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONException
import org.json.JSONObject

/** A parsed client request. */
data class Request(val id: Int?, val method: String, val params: JSONObject)

object Frames {
    /** Parses a request frame; null for anything that is not a JSON object with a string type. */
    fun parseRequest(text: String): Request? {
        val j = try {
            JSONObject(text)
        } catch (e: JSONException) {
            return null
        }
        val type = j.opt("type") as? String
        if (type.isNullOrEmpty()) return null
        var id: Int? = null
        if (j.has("id")) {
            id = when (val raw = j.get("id")) {
                is Int -> raw
                is Long -> if (raw in Int.MIN_VALUE..Int.MAX_VALUE) raw.toInt() else return null
                else -> return null
            }
        }
        j.remove("type")
        j.remove("id")
        return Request(id, type, j)
    }

    fun result(id: Int, data: JSONObject = JSONObject()): String =
        JSONObject().put("id", id).put("type", "result").put("data", data).toString()

    fun error(id: Int?, code: String, message: String): String = JSONObject().apply {
        if (id != null) put("id", id)
        put("type", "error")
        put("code", code)
        put("message", message)
    }.toString()

    fun event(name: String, data: JSONObject = JSONObject()): String =
        JSONObject().put("type", "event").put("event", name).put("data", data).toString()
}
