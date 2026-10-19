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

    @Test
    fun `correct code issues a stored token`() {
        val code = pairing.requestCode("iPhone")
        assertEquals(6, code.length)
        assertTrue(code.all(Char::isDigit))
        val r = pairing.confirm(" $code ") as PairingManager.ConfirmResult.Ok
        assertTrue(pairing.isValidToken(r.token))
        assertTrue(r.token.length >= 40)
        assertNull("code is single use", pairing.activeCode())
    }

    @Test
    fun `wrong codes count down then lock`() {
        val code = pairing.requestCode("iPhone")
        val wrong = if (code == "000000") "111111" else "000000"
        for (left in Protocol.MAX_FAILED_CODES - 1 downTo 1) {
            assertEquals(PairingManager.ConfirmResult.BadCode(left), pairing.confirm(wrong))
        }
        assertTrue(pairing.confirm(wrong) is PairingManager.ConfirmResult.Locked)
        val newCode = pairing.requestCode("iPhone")
        assertTrue("locked even with the right code", pairing.confirm(newCode) is PairingManager.ConfirmResult.Locked)
        now += Protocol.LOCK_SECONDS * 1000 + 1
        val again = pairing.requestCode("iPhone")
        assertTrue(pairing.confirm(again) is PairingManager.ConfirmResult.Ok)
    }

    @Test
    fun `codes expire`() {
        val code = pairing.requestCode("iPhone")
        now += Protocol.CODE_TTL_SECONDS * 1000 + 1
        assertEquals(PairingManager.ConfirmResult.NoPendingCode, pairing.confirm(code))
    }

    @Test
    fun `tokens can be revoked`() {
        val t = (pairing.confirm(pairing.requestCode("x")) as PairingManager.ConfirmResult.Ok).token
        pairing.revokeAll()
        assertFalse(pairing.isValidToken(t))
        assertFalse(pairing.isValidToken(null))
        assertFalse(pairing.isValidToken(""))
    }
}
