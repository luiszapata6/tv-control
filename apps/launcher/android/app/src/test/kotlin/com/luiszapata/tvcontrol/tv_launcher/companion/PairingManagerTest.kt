package com.luiszapata.tvcontrol.tv_launcher.companion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PairingManagerTest {
    private var now = 1_000_000L
    private val store = MemoryTokenStore()
    private val pairing = PairingManager(store, clock = { now })

    private fun code(client: String = "iPhone", owner: Any = client): String =
        (pairing.requestCode(client, owner) as PairingManager.RequestResult.Code).code

    @Test
    fun `correct code issues a stored token`() {
        val code = code()
        assertEquals(6, code.length)
        assertTrue(code.all(Char::isDigit))
        val r = pairing.confirm(" $code ") as PairingManager.ConfirmResult.Ok
        assertTrue(pairing.isValidToken(r.token))
        assertTrue(r.token.length >= 40)
        assertNull("code is single use", pairing.activeCode())
    }

    @Test
    fun `only token hashes are stored`() {
        val token = (pairing.confirm(code()) as PairingManager.ConfirmResult.Ok).token
        assertFalse(token in store.tokenHashes())
        assertEquals(setOf(PairingManager.hashToken(token)), store.tokenHashes())
        assertEquals(64, store.tokenHashes().single().length)
        assertFalse("a stored hash is not a token", pairing.isValidToken(store.tokenHashes().single()))
        assertFalse(pairing.isValidToken(token + "x"))
    }

    @Test
    fun `legacy plaintext entries never validate`() {
        val legacy = PairingManager(MemoryTokenStore(setOf("plain-token")), clock = { now })
        assertFalse(legacy.isValidToken("plain-token"))
    }

    @Test
    fun `wrong codes count down then lock`() {
        val code = code()
        val wrong = if (code == "000000") "111111" else "000000"
        for (left in Protocol.MAX_FAILED_CODES - 1 downTo 1) {
            assertEquals(PairingManager.ConfirmResult.BadCode(left), pairing.confirm(wrong))
        }
        assertTrue(pairing.confirm(wrong) is PairingManager.ConfirmResult.Locked)
        assertNull("the code is withdrawn on lock", pairing.activeCode())
        assertEquals(PairingManager.RequestResult.Locked(Protocol.LOCK_SECONDS), pairing.requestCode("iPhone"))
        assertTrue("locked even with a guess", pairing.confirm(code) is PairingManager.ConfirmResult.Locked)
        now += Protocol.LOCK_SECONDS * 1000 + 1
        assertTrue(pairing.confirm(code()) is PairingManager.ConfirmResult.Ok)
    }

    @Test
    fun `codes expire`() {
        val code = code()
        now += Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertNull(pairing.activeCode())
        assertEquals(PairingManager.ConfirmResult.NoPendingCode, pairing.confirm(code))
    }

    @Test
    fun `expired codes are swept once`() {
        code()
        assertFalse(pairing.expireIfStale())
        now += Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertTrue(pairing.expireIfStale())
        assertFalse(pairing.expireIfStale())
    }

    @Test
    fun `one active request at a time`() {
        val a = Any()
        val b = Any()
        val first = code("A", a)
        assertEquals(PairingManager.RequestResult.Busy, pairing.requestCode("B", b))
        assertEquals("A", pairing.requestedBy)
        assertTrue(pairing.isOwner(a))
        assertFalse(pairing.isOwner(b))
        assertEquals("others cannot confirm it", PairingManager.ConfirmResult.NoPendingCode, pairing.confirm(first, owner = b))
        val again = code("A", a)
        assertEquals("the owner may ask for a fresh code", again, pairing.activeCode())
        assertFalse(pairing.cancel(b))
        assertTrue(pairing.cancel(a))
        assertNull(pairing.activeCode())
        assertTrue(pairing.requestCode("B", b) is PairingManager.RequestResult.Code)
    }

    @Test
    fun `another device may request once the code expired`() {
        code("A", "a")
        now += Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertTrue(pairing.requestCode("B", "b") is PairingManager.RequestResult.Code)
    }

    @Test
    fun `tokens can be revoked`() {
        val t = (pairing.confirm(code("x")) as PairingManager.ConfirmResult.Ok).token
        pairing.revokeAll()
        assertFalse(pairing.isValidToken(t))
        assertFalse(pairing.isValidToken(null))
        assertFalse(pairing.isValidToken(""))
        assertTrue(store.tokenHashes().isEmpty())
    }
}
