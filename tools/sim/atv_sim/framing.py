"""Varint length-delimited framing used on both protocol ports."""

from __future__ import annotations


def encode_varint(value: int) -> bytes:
    out = bytearray()
    while True:
        byte = value & 0x7F
        value >>= 7
        if value:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def frame(payload: bytes) -> bytes:
    return encode_varint(len(payload)) + payload


class Deframer:
    """Accumulates bytes and yields complete messages."""

    def __init__(self) -> None:
        self._buf = bytearray()

    def feed(self, data: bytes) -> list[bytes]:
        self._buf += data
        messages: list[bytes] = []
        while True:
            length = 0
            shift = 0
            pos = 0
            complete = False
            while pos < len(self._buf):
                b = self._buf[pos]
                pos += 1
                length |= (b & 0x7F) << shift
                if not b & 0x80:
                    complete = True
                    break
                shift += 7
                if shift > 63:
                    raise ValueError("varint too long")
            if not complete or len(self._buf) < pos + length:
                return messages
            messages.append(bytes(self._buf[pos : pos + length]))
            del self._buf[: pos + length]
