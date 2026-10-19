from atv_sim.framing import Deframer, encode_varint, frame


def test_varint_round_trip():
    assert encode_varint(0) == b"\x00"
    assert encode_varint(300) == b"\xac\x02"


def test_deframer_handles_split_and_merged_messages():
    data = frame(b"a" * 200) + frame(b"bc") + frame(b"")
    d = Deframer()
    out = []
    for i in range(len(data)):
        out += d.feed(data[i : i + 1])
    assert out == [b"a" * 200, b"bc", b""]
    assert Deframer().feed(data) == [b"a" * 200, b"bc", b""]
