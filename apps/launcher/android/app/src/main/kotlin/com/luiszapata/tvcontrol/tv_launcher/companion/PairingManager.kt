package com.luiszapata.tvcontrol.tv_launcher.companion

import java.security.SecureRandom
import java.util.Base64

/** Where pairing tokens are kept (SharedPreferences on the TV, memory in tests). */
interface TokenStore {
    fun tokens(): Set<String>
    fun save(tokens: Set<String>)
}

class MemoryTokenStore(initial: Set<String> = emptySet()) : TokenStore {
    private var value = initial
    override fun tokens() = value
    override fun save(tokens: Set<String>) {
        value = tokens
    }
}

/**
 * Pairing rules shared with the protocol spec: a 6 digit code shown on the TV,
 * valid for [Protocol.CODE_TTL_SECONDS]; after [Protocol.MAX_FAILED_CODES]
 * wrong attempts pairing is locked for [Protocol.LOCK_SECONDS]. A correct code
 * yields a random 32-byte token the client stores.
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

    var code: String? = null
        private set
    var requestedBy: String? = null
        private set
    private var codeExpiresAt = 0L
    private var failures = 0
    private var lockedUntil = 0L

    @Synchronized
    fun isValidToken(token: String?): Boolean = token != null && token.isNotEmpty() && token in store.tokens()

    /** Creates (or refreshes) the code to show on screen. */
    @Synchronized
    fun requestCode(client: String): String {
        val c = "%06d".format(random.nextInt(1_000_000))
        code = c
        requestedBy = client
        codeExpiresAt = clock() + Protocol.CODE_TTL_SECONDS * 1000
        return c
    }

    /** Current code if still valid; expires it otherwise. */
    @Synchronized
    fun activeCode(): String? {
        if (code != null && clock() > codeExpiresAt) clearCode()
        return code
    }

    @Synchronized
    fun confirm(input: String): ConfirmResult {
        val now = clock()
        if (now < lockedUntil) return ConfirmResult.Locked((lockedUntil - now + 999) / 1000)
        val expected = activeCode() ?: return ConfirmResult.NoPendingCode
        if (input.trim() == expected) {
            failures = 0
            clearCode()
            val token = Base64.getUrlEncoder().withoutPadding().encodeToString(ByteArray(32).also(random::nextBytes))
            store.save(store.tokens() + token)
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
    }

    /** Forgets every paired iPhone. */
    @Synchronized
    fun revokeAll() = store.save(emptySet())
}
