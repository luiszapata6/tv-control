package com.luiszapata.tvcontrol.tv_launcher.companion

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo

/** Announces the companion service as `_tvcontrol._tcp` so the iPhone finds it. */
class NsdAdvertiser(context: Context) {
    private val nsd = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private var listener: NsdManager.RegistrationListener? = null

    fun start(name: String, port: Int, deviceId: String) {
        stop()
        val info = NsdServiceInfo().apply {
            serviceName = name
            serviceType = Protocol.MDNS_TYPE
            setPort(port)
            setAttribute("v", Protocol.VERSION.toString())
            setAttribute("id", deviceId)
            setAttribute("name", name)
        }
        val l = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(info: NsdServiceInfo) {}
            override fun onRegistrationFailed(info: NsdServiceInfo, errorCode: Int) {}
            override fun onServiceUnregistered(info: NsdServiceInfo) {}
            override fun onUnregistrationFailed(info: NsdServiceInfo, errorCode: Int) {}
        }
        listener = l
        nsd.registerService(info, NsdManager.PROTOCOL_DNS_SD, l)
    }

    fun stop() {
        listener?.let {
            try {
                nsd.unregisterService(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        listener = null
    }
}
