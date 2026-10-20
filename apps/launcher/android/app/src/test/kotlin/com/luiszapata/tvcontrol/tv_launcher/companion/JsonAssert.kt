package com.luiszapata.tvcontrol.tv_launcher.companion

import org.json.JSONArray
import org.json.JSONObject

/** Deep JSON equality (the Android stub of org.json has no `similar`). */
fun jsonEquals(a: Any?, b: Any?): Boolean = when {
    a is JSONObject && b is JSONObject ->
        a.keys().asSequence().toSet() == b.keys().asSequence().toSet() &&
            a.keys().asSequence().all { jsonEquals(a.opt(it), b.opt(it)) }
    a is JSONArray && b is JSONArray ->
        a.length() == b.length() && (0 until a.length()).all { jsonEquals(a.opt(it), b.opt(it)) }
    a is Number && b is Number -> a.toDouble() == b.toDouble()
    a == null || a == JSONObject.NULL -> b == null || b == JSONObject.NULL
    else -> a == b
}
