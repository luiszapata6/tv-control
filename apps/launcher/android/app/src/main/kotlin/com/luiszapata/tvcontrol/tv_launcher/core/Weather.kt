package com.luiszapata.tvcontrol.tv_launcher.core

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.roundToInt

/** Current conditions from Open-Meteo (free, no API key). */
data class Weather(val temperatureC: Double, val code: Int, val isDay: Boolean) {
    val temperatureLabel: String get() = "${temperatureC.roundToInt()}°"
    val label: String get() = describe(code)

    companion object {
        const val PLACE = "Medellín"
        private const val URL_MEDELLIN = "https://api.open-meteo.com/v1/forecast?latitude=6.2442&longitude=-75.5812" +
            "&current=temperature_2m,weather_code,is_day&timezone=auto"

        /** Null on any failure: the weather simply hides. Blocking: call off the main thread. */
        fun fetch(): Weather? = try {
            val c = URL(URL_MEDELLIN).openConnection() as HttpURLConnection
            c.connectTimeout = 6000
            c.readTimeout = 8000
            try {
                if (c.responseCode == 200) parse(c.inputStream.bufferedReader().readText()) else null
            } finally {
                c.disconnect()
            }
        } catch (e: Exception) {
            null
        }

        fun parse(body: String): Weather? = try {
            val cur = JSONObject(body).optJSONObject("current") ?: return null
            if (!cur.has("temperature_2m") || !cur.has("weather_code")) return null
            Weather(cur.getDouble("temperature_2m"), cur.getInt("weather_code"), cur.optInt("is_day", 1) != 0)
        } catch (e: Exception) {
            null
        }

        fun describe(code: Int): String = when (code) {
            0 -> "Despejado"
            1 -> "Mayormente despejado"
            2 -> "Parcialmente nublado"
            3 -> "Nublado"
            45, 48 -> "Niebla"
            51, 53, 55, 56, 57 -> "Llovizna"
            61, 63, 65, 66, 67 -> "Lluvia"
            71, 73, 75, 77 -> "Nieve"
            80, 81, 82 -> "Chubascos"
            85, 86 -> "Chubascos de nieve"
            95, 96, 99 -> "Tormenta"
            else -> "Clima"
        }
    }
}
