package com.luiszapata.tvcontrol.tv_launcher.companion

/** Constants shared with packages/companion_protocol (see PROTOCOL.md). */
object Protocol {
    const val VERSION = 1
    const val PORT = 7790
    const val PATH = "/v1"
    const val MDNS_TYPE = "_tvcontrol._tcp"
    const val MAX_FAILED_CODES = 5
    const val LOCK_SECONDS = 60L
    const val CODE_TTL_SECONDS = 120L

    /** Connections that have not authenticated (or own the pending code) are closed after this. */
    const val UNAUTHENTICATED_TIMEOUT_MS = 30_000L

    /** Text frames larger than this are refused (close code 1009). */
    const val MAX_FRAME_BYTES = 64 * 1024

    /** Further connections are refused (close code 1013). */
    const val MAX_CONNECTIONS = 8

    /** Max width and height of `apps.icon` PNGs. */
    const val MAX_ICON_PX = 192

    object Close {
        const val POLICY = 1008
        const val TOO_BIG = 1009
        const val TRY_AGAIN_LATER = 1013
        const val REVOKED = 4001
    }

    /** True for `/v1` and `/v1?query`, not `/v10` or `/v1/x`. */
    fun isProtocolPath(resource: String?): Boolean {
        if (resource == null) return false
        return resource.substringBefore('?') == PATH
    }

    object Method {
        const val HELLO = "hello"
        const val PAIR_REQUEST = "pair.request"
        const val PAIR_CONFIRM = "pair.confirm"
        const val PING = "ping"
        const val APPS_LIST = "apps.list"
        const val APPS_ICON = "apps.icon"
        const val APPS_LAUNCH = "apps.launch"
        const val LAUNCHER_GET = "launcher.get"
        const val LAUNCHER_SET = "launcher.set"
        const val INPUTS_LIST = "inputs.list"
        const val INPUTS_OPEN = "inputs.open"
        const val NOW_PLAYING_GET = "nowPlaying.get"
        const val USAGE_GET = "usage.get"
        const val BACKUP_EXPORT = "backup.export"
        const val BACKUP_IMPORT = "backup.import"

        val PUBLIC = setOf(HELLO, PAIR_REQUEST, PAIR_CONFIRM, PING)
    }

    object Event {
        const val NOW_PLAYING = "nowPlaying"
        const val FOREGROUND_APP = "foregroundApp"
        const val LAYOUT_CHANGED = "layoutChanged"
        const val APPS_CHANGED = "appsChanged"
    }

    object Error {
        const val AUTH_REQUIRED = "auth_required"
        const val BAD_CODE = "bad_code"
        const val LOCKED = "locked"
        const val BUSY = "busy"
        const val NOT_FOUND = "not_found"
        const val BAD_REQUEST = "bad_request"
        const val UNSUPPORTED = "unsupported"
        const val INTERNAL = "internal"
    }
}
