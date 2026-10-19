"""Validate the simulator against the reference client (androidtvremote2).

If these pass, the simulator speaks the same protocol a real TV does as far as
the reference implementation can tell, so it is a fair stand-in for testing our
own Dart client.
"""

from __future__ import annotations

import asyncio

import pytest
from androidtvremote2 import AndroidTVRemote, ConnectionClosed, InvalidAuth

from cryptography import x509

from atv_sim import TvSimulator
from atv_sim.certs import pairing_hash


def client(sim: TvSimulator, tmp_path, name: str = "pytest") -> AndroidTVRemote:
    return AndroidTVRemote(
        client_name=name,
        certfile=str(tmp_path / f"{name}.pem"),
        keyfile=str(tmp_path / f"{name}.key"),
        host="127.0.0.1",
        api_port=sim.remote_port,
        pair_port=sim.pairing_port,
    )


async def pair(sim: TvSimulator, remote: AndroidTVRemote) -> None:
    await remote.async_generate_cert_if_missing()
    await remote.async_start_pairing()
    code = (await asyncio.to_thread(sim.wait_for, "pairing_code")).data["code"]
    await remote.async_finish_pairing(code)


async def test_pairing_then_connect_reports_state(sim, tmp_path):
    remote = client(sim, tmp_path)
    await pair(sim, remote)
    req = sim.wait_for("pairing_request")
    assert req.data["client_name"] == "pytest"
    assert req.data["service_name"] == "atvremote"
    sim.wait_for("paired")

    await remote.async_connect()
    try:
        assert remote.is_on is True
        assert remote.device_info == {"manufacturer": "Hisense", "model": "65U6GA", "sw_version": "5.2.473254133"}
        await asyncio.sleep(0.2)
        assert remote.volume_info == {"level": 18, "max": 100, "muted": False}
        assert remote.current_app == "com.google.android.tvlauncher"
    finally:
        remote.disconnect()


async def test_name_and_mac_from_server_certificate(sim, tmp_path):
    remote = client(sim, tmp_path)
    await remote.async_generate_cert_if_missing()
    name, mac = await remote.async_get_name_and_mac()
    assert name == "Hisense 65U6GA"
    assert mac == "AA:BB:CC:DD:EE:FF"


async def test_keys_text_and_app_links_reach_the_tv(sim, tmp_path):
    remote = client(sim, tmp_path)
    await pair(sim, remote)
    await remote.async_connect()
    try:
        volumes = []
        apps = []
        remote.add_volume_info_updated_callback(volumes.append)
        remote.add_current_app_updated_callback(apps.append)

        remote.send_key_command("DPAD_UP")
        remote.send_key_command("VOLUME_UP")
        remote.send_key_command("KEYCODE_ENTER", "START_LONG")
        remote.send_launch_app_command("https://www.youtube.com")
        remote.send_launch_app_command("com.netflix.ninja")
        await asyncio.sleep(0.3)
        remote.send_text("hola mundo")

        await asyncio.to_thread(sim.wait_for, "key", key="KEYCODE_DPAD_UP", direction="SHORT")
        await asyncio.to_thread(sim.wait_for, "key", key="KEYCODE_ENTER", direction="START_LONG")
        await asyncio.to_thread(sim.wait_for, "app_link", link="market://launch?id=com.netflix.ninja")
        await asyncio.to_thread(sim.wait_for, "text", text="hola mundo")
        await asyncio.sleep(0.3)
        assert volumes[-1]["level"] == 19
        assert "com.google.android.youtube.tv" in apps
        assert apps[-1] == "com.netflix.ninja"
        assert sim.state.ime_text == "hola mundo"
    finally:
        remote.disconnect()


async def test_power_and_mute_round_trip(sim, tmp_path):
    remote = client(sim, tmp_path)
    await pair(sim, remote)
    await remote.async_connect()
    try:
        power = []
        remote.add_is_on_updated_callback(power.append)
        remote.send_key_command("POWER")
        remote.send_key_command("VOLUME_MUTE")
        await asyncio.sleep(0.4)
        assert power[-1] is False
        assert remote.volume_info["muted"] is True
    finally:
        remote.disconnect()


async def test_pings_are_answered_and_connection_stays_up(sim, tmp_path):
    remote = client(sim, tmp_path)
    await pair(sim, remote)
    await remote.async_connect()
    try:
        await asyncio.to_thread(sim.wait_for, "pong", 3.0)
        await asyncio.sleep(1.6)  # three ping intervals
        assert len(sim.events_of("pong")) >= 3
        assert not sim.events_of("ping_timeout")
    finally:
        remote.disconnect()


async def test_wrong_code_is_rejected(sim, tmp_path):
    remote = client(sim, tmp_path)
    await remote.async_generate_cert_if_missing()
    await remote.async_start_pairing()
    code = (await asyncio.to_thread(sim.wait_for, "pairing_code")).data["code"]
    # Build a code for a different nonce whose check byte is self-consistent, so
    # the client's local check passes and the TV is the one that rejects it.
    client_cert = x509.load_pem_x509_certificate((tmp_path / "pytest.pem").read_bytes())
    nonce = (int(code[2:], 16) + 1) % 0x10000
    digest = pairing_hash(client_cert, sim.server_cert, nonce.to_bytes(2, "big"))
    wrong = f"{digest[0]:02X}{nonce:04X}"
    with pytest.raises((InvalidAuth, ConnectionClosed)):
        await remote.async_finish_pairing(wrong)
    sim.wait_for("pairing_failed")
    with pytest.raises(InvalidAuth):
        await remote.async_connect()


async def test_unpaired_client_cannot_use_remote_port(sim, tmp_path):
    remote = client(sim, tmp_path)
    await remote.async_generate_cert_if_missing()
    with pytest.raises((InvalidAuth, ConnectionClosed)):
        await remote.async_connect()
    sim.wait_for("tls_rejected")


async def test_pairing_survives_restart(tmp_path):
    state_dir = tmp_path / "tv"
    with TvSimulator(state_dir=state_dir) as first:
        remote = client(first, tmp_path)
        await pair(first, remote)
        ports = (first.pairing_port, first.remote_port)
    with TvSimulator(pairing_port=ports[0], remote_port=ports[1], state_dir=state_dir) as second:
        remote = client(second, tmp_path)
        await remote.async_connect()
        assert remote.is_on is True
        remote.disconnect()


async def test_server_pushes_external_changes(sim, tmp_path):
    remote = client(sim, tmp_path)
    await pair(sim, remote)
    await remote.async_connect()
    try:
        volumes = []
        remote.add_volume_info_updated_callback(volumes.append)
        await asyncio.sleep(0.2)
        sim.set_volume(42)
        await asyncio.sleep(0.3)
        assert volumes[-1]["level"] == 42
    finally:
        remote.disconnect()
