package com.luiszapata.tvcontrol.tv_launcher.companion

import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64

/**
 * Where pairing token hashes are kept (SharedPreferences on the TV, memory in
 * tests). Only SHA-256 hashes (lowercase hex) are stored, never the tokens.
 */
interface TokenStore {
    fun tokenHashes(): Set<String>
    fun save(tokenHashes: Set<String>)
}

class MemoryTokenStore(initial: Set<String> = emptySet()) : TokenStore {
    private var value = initial
    override fun tokenHashes() = value
    override fun save(tokenHashes: Set<String>) {
        value = tokenHashes
    }
}

/**
 * Pairing rules shared with the protocol spec: a 6 digit code shown on the TV,
 * valid for [Protocol.CODE_TTL_SECONDS]; after [Protocol.MAX_FAILED_CODES]
 * wrong attempts pairing is locked for [Protocol.LOCK_SECONDS]. A correct code
 * yields a random 32-byte token the client stores; the TV keeps its hash.
 *
 * Only one code is active at a time and it belongs to the connection
 * (`owner`) that requested it; other connections are refused with
 * [RequestResult.Busy] until it is confirmed, expires or its owner disconnects.
 */
class PairingManager(
    private val store: TokenStore,
    private val clock: () -> Long = System::currentTimeMillis,
    private val random: SecureRandom = SecureRandom(),
) {
    sealed interface ConfirmResult {
        data class Ok(val token: String) : ConfirmResult
        data class BadCode(val attemptsLeft: Int) : ConfirmResult
        data class Locked(val secondsLeft: Long) : ConfirmResult
        data object NoPendingCode : ConfirmResult
    }

    sealed interface RequestResult {
        data class Code(val code: String) : RequestResult
        data object Busy : RequestResult
        data class Locked(val secondsLeft: Long) : RequestResult
    }

    private var code: String? = null
    var requestedBy: String? = null
        private set
    private var owner: Any? = null
    private var codeExpiresAt = 0L
    private var failures = 0
    private var lockedUntil = 0L

    @Synchronized
    fun isValidToken(token: String?): Boolean {
        if (token.isNullOrEmpty()) return false
        val hash = hashToken(token).toByteArray(Charsets.US_ASCII)
        var match = false
        // Constant time per entry and no early exit.
        for (stored in store.tokenHashes()) {
            if (MessageDigest.isEqual(stored.toByteArray(Charsets.US_ASCII), hash)) match = true
        }
        return match
    }

    /**
     * Creates the code to show on screen for [owner]. The same owner may ask
     * again (a fresh code); others get [RequestResult.Busy] while it is live.
     */
    @Synchronized
    fun requestCode(client: String, owner: Any = client): RequestResult {
        val now = clock()
        if (now < lockedUntil) return RequestResult.Locked(secondsUntil(lockedUntil, now))
        if (isLive(now) && this.owner !== owner) return RequestResult.Busy
        val c = "%06d".format(random.nextInt(1_000_000))
        code = c
        requestedBy = client
        this.owner = owner
        codeExpiresAt = now + Protocol.CODE_TTL_SECONDS * 1000
        return RequestResult.Code(c)
    }

    /** Current code if still valid (does not change state). */
    @Synchronized
    fun activeCode(): String? = if (isLive(clock())) code else null

    @Synchronized
    fun isOwner(owner: Any): Boolean = isLive(clock()) && this.owner === owner

    /** Clears an expired code; true if one was cleared (so the TV must hide it). */
    @Synchronized
    fun expireIfStale(): Boolean {
        if (code == null || isLive(clock())) return false
        clearCode()
        return true
    }

    /** Clears the code if [owner] requested it (its connection closed); true if cleared. */
    @Synchronized
    fun cancel(owner: Any): Boolean {
        if (code == null || this.owner !== owner) return false
        clearCode()
        return true
    }

    /**
     * Checks [input] against the active code. With an [owner], only the
     * connection that requested the code can confirm it.
     */
    @Synchronized
    fun confirm(input: String, owner: Any? = null): ConfirmResult {
        val now = clock()
        if (now < lockedUntil) return ConfirmResult.Locked(secondsUntil(lockedUntil, now))
        if (code != null && !isLive(now)) clearCode()
        val expected = code ?: return ConfirmResult.NoPendingCode
        if (owner != null && this.owner !== owner) return ConfirmResult.NoPendingCode
        if (MessageDigest.isEqual(input.trim().toByteArray(Charsets.UTF_8), expected.toByteArray(Charsets.UTF_8))) {
            failures = 0
            clearCode()
            val token = Base64.getUrlEncoder().withoutPadding().encodeToString(ByteArray(32).also(random::nextBytes))
            store.save(store.tokenHashes() + hashToken(token))
            return ConfirmResult.Ok(token)
        }
        failures++
        if (failures >= Protocol.MAX_FAILED_CODES) {
            failures = 0
            lockedUntil = now + Protocol.LOCK_SECONDS * 1000
            clearCode()
            return ConfirmResult.Locked(Protocol.LOCK_SECONDS)
        }
        return ConfirmResult.BadCode(Protocol.MAX_FAILED_CODES - failures)
    }

    @Synchronized
    fun clearCode() {
        code = null
        requestedBy = null
        owner = null
    }

    /** Forgets every paired iPhone. */
    @Synchronized
    fun revokeAll() = store.save(emptySet())

    private fun isLive(now: Long) = code != null && now <= codeExpiresAt

    private fun secondsUntil(t: Long, now: Long) = (t - now + 999) / 1000

    companion object {
        /** Lowercase hex SHA-256 of the token's UTF-8 bytes. */
        fun hashToken(token: String): String =
            MessageDigest.getInstance("SHA-256").digest(token.toByteArray(Charsets.UTF_8))
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }
}
