package com.luiszapata.tvcontrol.tv_launcher.companion

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ProtocolTest {
    @Test
    fun `only the v1 path is accepted`() {
        assertTrue(Protocol.isProtocolPath("/v1"))
        assertTrue(Protocol.isProtocolPath("/v1?client=iphone"))
        assertFalse(Protocol.isProtocolPath("/v10"))
        assertFalse(Protocol.isProtocolPath("/v1/"))
        assertFalse(Protocol.isProtocolPath("/v1x?a=b"))
        assertFalse(Protocol.isProtocolPath("/"))
        assertFalse(Protocol.isProtocolPath(""))
        assertFalse(Protocol.isProtocolPath(null))
    }

    @Test
    fun `icons fit in 192 px`() {
        assertEquals(192 to 108, fitIconSize(320, 180))
        assertEquals(108 to 192, fitIconSize(180, 320))
        assertEquals(192 to 192, fitIconSize(512, 512))
        assertEquals("small icons are not scaled up", 96 to 96, fitIconSize(96, 96))
        assertEquals(192 to 1, fitIconSize(4000, 1))
        val (w, h) = fitIconSize(1000, 999)
        assertTrue(maxOf(w, h) <= Protocol.MAX_ICON_PX)
    }
}
