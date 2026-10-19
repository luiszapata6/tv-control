#!/usr/bin/env python3
"""Generate golden test vectors for packages/atv_remote from the reference
Python implementation. The Dart tests assert byte-for-byte equality with these.

Usage:  python tools/codegen/gen_golden.py
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/sim"))

from androidtvremote2.polo_pb2 import Options, OuterMessage  # noqa: E402
from androidtvremote2.remotemessage_pb2 import (  # noqa: E402
    RemoteDirection,
    RemoteEditInfo,
    RemoteImeBatchEdit,
    RemoteImeObject,
    RemoteKeyCode,
    RemoteMessage,
)
from cryptography import x509  # noqa: E402
from cryptography.hazmat.primitives import serialization  # noqa: E402

from atv_sim.certs import make_server_cert, pairing_hash, rsa_numbers  # noqa: E402
from atv_sim.framing import frame  # noqa: E402

OUT = ROOT / "packages/atv_remote/test/fixtures/golden.json"


def outer() -> OuterMessage:
    m = OuterMessage()
    m.protocol_version = 2
    m.status = OuterMessage.Status.STATUS_OK
    return m


def polo_vectors() -> dict[str, str]:
    v: dict[str, str] = {}
    m = outer()
    m.pairing_request.client_name = "TV Control"
    m.pairing_request.service_name = "atvremote"
    v["pairing_request"] = m.SerializeToString().hex()

    m = outer()
    m.pairing_request_ack.server_name = "Hisense 65U6GA"
    v["pairing_request_ack"] = m.SerializeToString().hex()

    m = outer()
    m.options.preferred_role = Options.RoleType.ROLE_TYPE_INPUT
    enc = m.options.input_encodings.add()
    enc.type = Options.Encoding.ENCODING_TYPE_HEXADECIMAL
    enc.symbol_length = 6
    v["options"] = m.SerializeToString().hex()

    m = outer()
    m.configuration.client_role = Options.RoleType.ROLE_TYPE_INPUT
    m.configuration.encoding.type = Options.Encoding.ENCODING_TYPE_HEXADECIMAL
    m.configuration.encoding.symbol_length = 6
    v["configuration"] = m.SerializeToString().hex()

    m = outer()
    m.configuration_ack.SetInParent()
    v["configuration_ack"] = m.SerializeToString().hex()

    m = outer()
    m.secret.secret = bytes(range(32))
    v["secret"] = m.SerializeToString().hex()

    m = outer()
    m.secret_ack.secret = bytes(range(32))
    v["secret_ack"] = m.SerializeToString().hex()

    m = OuterMessage()
    m.protocol_version = 2
    m.status = OuterMessage.Status.STATUS_BAD_SECRET
    v["bad_secret"] = m.SerializeToString().hex()
    return v


def remote_vectors() -> dict[str, str]:
    v: dict[str, str] = {}

    def put(name: str, m: RemoteMessage) -> None:
        v[name] = m.SerializeToString().hex()

    # client -> TV, exactly as androidtvremote2.remote builds them
    m = RemoteMessage()
    m.remote_configure.code1 = 622
    m.remote_configure.device_info.unknown1 = 1
    m.remote_configure.device_info.unknown2 = "1"
    m.remote_configure.device_info.package_name = "atvremote"
    m.remote_configure.device_info.app_version = "1.0.0"
    put("client_configure", m)

    m = RemoteMessage()
    m.remote_set_active.active = 622
    put("client_set_active", m)

    m = RemoteMessage()
    m.remote_key_inject.key_code = RemoteKeyCode.KEYCODE_DPAD_UP
    m.remote_key_inject.direction = RemoteDirection.SHORT
    put("key_dpad_up_short", m)

    m = RemoteMessage()
    m.remote_key_inject.key_code = RemoteKeyCode.KEYCODE_DPAD_CENTER
    m.remote_key_inject.direction = RemoteDirection.START_LONG
    put("key_center_start_long", m)

    m = RemoteMessage()
    m.remote_key_inject.key_code = RemoteKeyCode.KEYCODE_POWER
    m.remote_key_inject.direction = RemoteDirection.SHORT
    put("key_power_short", m)

    m = RemoteMessage()
    m.remote_app_link_launch_request.app_link = "market://launch?id=com.netflix.ninja"
    put("app_link_netflix", m)

    text = "hola mundo"
    obj = RemoteImeObject(start=len(text) - 1, end=len(text) - 1, value=text)
    m = RemoteMessage()
    m.remote_ime_batch_edit.CopyFrom(
        RemoteImeBatchEdit(ime_counter=7, field_counter=3, edit_info=[RemoteEditInfo(insert=1, text_field_status=obj)])
    )
    put("ime_text_hola_mundo", m)

    m = RemoteMessage()
    m.remote_ping_response.val1 = 42
    put("ping_response_42", m)

    # int32 with a negative value -> 10 byte varint
    m = RemoteMessage()
    m.remote_ime_batch_edit.ime_counter = -1
    put("negative_int32", m)

    # TV -> client
    m = RemoteMessage()
    m.remote_configure.code1 = 622
    m.remote_configure.device_info.model = "65U6GA"
    m.remote_configure.device_info.vendor = "Hisense"
    m.remote_configure.device_info.unknown1 = 1
    m.remote_configure.device_info.unknown2 = "1"
    m.remote_configure.device_info.package_name = "com.google.android.tv.remote.service"
    m.remote_configure.device_info.app_version = "5.2.473254133"
    put("tv_configure", m)

    m = RemoteMessage()
    m.remote_set_active.SetInParent()
    put("tv_set_active_empty", m)

    m = RemoteMessage()
    m.remote_start.started = True
    put("tv_start_true", m)

    m = RemoteMessage()
    m.remote_start.SetInParent()  # started = False is not serialized in proto3
    put("tv_start_false", m)

    m = RemoteMessage()
    m.remote_set_volume_level.volume_max = 100
    m.remote_set_volume_level.volume_level = 18
    m.remote_set_volume_level.volume_muted = True
    m.remote_set_volume_level.player_model = "65U6GA"
    put("tv_volume_18_muted", m)

    m = RemoteMessage()
    m.remote_ime_key_inject.app_info.app_package = "com.google.android.youtube.tv"
    put("tv_ime_key_inject_youtube", m)

    m = RemoteMessage()
    m.remote_ime_batch_edit.ime_counter = 12
    m.remote_ime_batch_edit.field_counter = 4
    put("tv_ime_batch_edit_counters", m)

    m = RemoteMessage()
    m.remote_ping_request.val1 = 42
    m.remote_ping_request.val2 = 1
    put("tv_ping_request", m)

    m = RemoteMessage()
    m.remote_error.value = True
    m.remote_error.message.remote_key_inject.key_code = RemoteKeyCode.KEYCODE_HOME
    put("tv_error_nested", m)
    return v


def pairing_vectors() -> list[dict]:
    out = []
    client_pem, client_key = make_server_cert("client", "client", "00:00:00:00:00:00")
    server_pem, _ = make_server_cert("65U6GA", "Hisense 65U6GA", "AA:BB:CC:DD:EE:FF")
    client = x509.load_pem_x509_certificate(client_pem)
    server = x509.load_pem_x509_certificate(server_pem)
    for nonce in (b"\x00\x00", b"\x12\xab", b"\xff\xff"):
        digest = pairing_hash(client, server, nonce)
        cn, ce = rsa_numbers(client)
        sn, se = rsa_numbers(server)
        out.append(
            {
                "client_cert_pem": client_pem.decode(),
                "server_cert_der": server.public_bytes(serialization.Encoding.DER).hex(),
                "client_modulus_hex": f"{cn:x}",
                "client_exponent": ce,
                "server_modulus_hex": f"{sn:x}",
                "server_exponent": se,
                "server_subject_cn": server.subject.rfc4514_string(),
                "nonce_hex": nonce.hex(),
                "secret_hex": digest.hex(),
                "code": f"{digest[0]:02X}{nonce.hex().upper()}",
            }
        )
    return out


def main() -> None:
    golden = {
        "polo": polo_vectors(),
        "remote": remote_vectors(),
        "pairing": pairing_vectors(),
        "framing": {
            "empty": frame(b"").hex(),
            "short": frame(b"\x01\x02\x03").hex(),
            "long_300": frame(bytes(300)).hex()[:8],
        },
        "keycodes": {name: value for name, value in RemoteKeyCode.items()},
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(golden, indent=1, sort_keys=True) + "\n")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
