#!/usr/bin/env python3
"""Fase 0 — valida la TV real antes de confiar en el plan.

Qué hace (te pregunta antes de cada cosa que cambia algo en la TV):
  1. Busca la TV en la red (mDNS) o usa la IP que le pases.
  2. Lee nombre y MAC del certificado de la TV (la MAC sirve para Wake-on-LAN).
  3. Empareja (la TV muestra un código de 6 caracteres) y se conecta.
  4. Reporta encendido, volumen, app activa, modelo y funciones soportadas.
  5. Prueba teclas inofensivas, volumen +/- , abrir YouTube y escribir texto.
  6. Si tienes `adb` y la depuración por red activa: launcher actual, entradas
     HDMI, memoria, versión de Android, MAC y ajustes de encendido por red.

Resultado: tools/validate/out/phase0-report.md y .json
"""

from __future__ import annotations

import argparse
import asyncio
import json
import pathlib
import shutil
import subprocess
import sys
import time

from androidtvremote2 import AndroidTVRemote, CannotConnect, ConnectionClosed, InvalidAuth

OUT = pathlib.Path(__file__).resolve().parent / "out"
CERT = OUT / "client.pem"
KEY = OUT / "client.key"
report: dict = {"started": time.strftime("%Y-%m-%d %H:%M:%S"), "checks": {}}


def ok(name: str, value, passed: bool = True, note: str = "") -> None:
    report["checks"][name] = {"ok": passed, "value": value, "note": note}
    print(f"  [{'OK' if passed else '!!'}] {name}: {value}{(' — ' + note) if note else ''}")


def ask(question: str) -> bool:
    return input(f"\n{question} [s/N] ").strip().lower() in ("s", "si", "sí", "y", "yes")


def discover(timeout: float = 6.0) -> list[dict]:
    try:
        from zeroconf import ServiceBrowser, ServiceListener, Zeroconf
    except ImportError:
        return []
    found: dict[str, dict] = {}

    class Listener(ServiceListener):
        def add_service(self, zc, type_, name):
            info = zc.get_service_info(type_, name, 3000)
            if info:
                found[name] = {
                    "name": name.split(".")[0],
                    "addresses": info.parsed_addresses(),
                    "port": info.port,
                    "txt": {k.decode(): (v.decode() if v else "") for k, v in info.properties.items()},
                }

        def update_service(self, *a):
            pass

        def remove_service(self, *a):
            pass

    zc = Zeroconf()
    ServiceBrowser(zc, "_androidtvremote2._tcp.local.", Listener())
    time.sleep(timeout)
    zc.close()
    return list(found.values())


def adb(*args: str, timeout: int = 15) -> str:
    try:
        r = subprocess.run(["adb", *args], capture_output=True, text=True, timeout=timeout)
        return (r.stdout + r.stderr).strip()
    except Exception as exc:  # noqa: BLE001
        return f"error: {exc}"


def adb_probes(ip: str) -> None:
    print("\n== ADB (depuración por red) ==")
    if not shutil.which("adb"):
        ok("adb", "no instalado", False, "instala Android platform-tools: brew install android-platform-tools")
        return
    out = adb("connect", f"{ip}:5555")
    ok("adb connect", out, "connected" in out, "si dice 'failed to authenticate', acepta el aviso en la TV y vuelve a correr")
    if "connected" not in out:
        return
    target = ["-s", f"{ip}:5555"]
    sh = lambda cmd: adb(*target, "shell", cmd)  # noqa: E731
    ok("modelo", sh("getprop ro.product.model"))
    ok("android", f"{sh('getprop ro.build.version.release')} (SDK {sh('getprop ro.build.version.sdk')})")
    home = sh("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME").splitlines()
    launcher = home[-1].split("/")[0] if home else ""
    ok("launcher actual", launcher, bool(launcher), "este es el paquete a desactivar en la Fase 4")
    homes = sh("cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME")
    ok("apps HOME instaladas", [l.split("/")[0] for l in homes.splitlines() if "/" in l])
    pkgs = sh("pm list packages -3").splitlines()
    ok("apps de terceros", len(pkgs))
    inputs = [l.strip() for l in sh("dumpsys tv_input").splitlines() if "HDMI" in l.upper() and ("id=" in l or "inputId" in l)]
    ok("entradas HDMI (TvInputManager)", inputs[:8], bool(inputs), "si está vacío, los accesos HDMI usarán KEYCODE_TV_INPUT_HDMI_n")
    mem = sh(f"dumpsys meminfo {launcher} | grep -i 'TOTAL'") if launcher else ""
    ok("memoria del launcher actual", mem.splitlines()[0] if mem else "n/d")
    ok("RAM total", sh("cat /proc/meminfo | head -1"))
    macs = {i: sh(f"cat /sys/class/net/{i}/address") for i in ("wlan0", "eth0")}
    ok("MAC por interfaz", macs)
    wake = [l for l in sh("settings list global").splitlines() if any(w in l.lower() for w in ("wake", "wol", "network_standby", "instant"))]
    ok("ajustes de encendido por red", wake[:10], bool(wake), "busca algo como 'Wake on LAN/Wi-Fi' en Ajustes > Red si está vacío")
    ok("notification listener (reproducción actual)", sh("cmd notification allowed_listeners 0") or "(vacío)")


async def run(args: argparse.Namespace) -> None:
    OUT.mkdir(exist_ok=True)
    ip = args.ip
    print("== Descubrimiento ==")
    found = discover()
    ok("TVs encontradas por mDNS", found, bool(found), "si está vacío, el iPhone necesitará la IP manual")
    if not ip:
        if not found:
            ip = input("No encontré la TV. Escribe su IP: ").strip()
        else:
            ip = found[0]["addresses"][0]
    report["ip"] = ip

    remote = AndroidTVRemote("TV Control (Fase 0)", str(CERT), str(KEY), ip)
    if await remote.async_generate_cert_if_missing():
        print("  certificado de cliente nuevo generado")

    print("\n== Certificado de la TV ==")
    try:
        name, mac = await remote.async_get_name_and_mac()
        ok("nombre", name)
        ok("MAC (para Wake-on-LAN)", mac)
    except CannotConnect as exc:
        ok("puerto 6467", f"sin respuesta: {exc}", False, "¿la IP es correcta? ¿TV encendida?")
        return

    print("\n== Conexión ==")
    try:
        await remote.async_connect()
        ok("ya emparejado", True)
    except InvalidAuth:
        print("  La TV va a mostrar un código de 6 caracteres.")
        await remote.async_start_pairing()
        while True:
            code = input("  Código que aparece en la TV: ").strip()
            try:
                await remote.async_finish_pairing(code)
                ok("emparejamiento", True)
                break
            except InvalidAuth as exc:
                print(f"  Código inválido ({exc}). Intenta de nuevo.")
            except ConnectionClosed:
                ok("emparejamiento", "cancelado en la TV", False)
                return
        await remote.async_connect()
    except (CannotConnect, ConnectionClosed) as exc:
        ok("puerto 6466", str(exc), False)
        return

    await asyncio.sleep(1.5)
    ok("encendida", remote.is_on)
    ok("info del dispositivo", remote.device_info)
    ok("volumen", remote.volume_info, remote.volume_info is not None)
    ok("app activa", remote.current_app, bool(remote.current_app), "vacío = la TV no reporta app (IME)")
    ok("voz soportada", remote.is_voice_enabled)

    if ask("¿Pruebo flechas (abajo y arriba) en la TV?"):
        remote.send_key_command("DPAD_DOWN")
        await asyncio.sleep(0.6)
        remote.send_key_command("DPAD_UP")
        ok("teclas", input("  ¿Viste moverse la selección? [s/N] ").strip().lower().startswith("s"))
    if ask("¿Pruebo volumen +1 y luego -1?"):
        before = (remote.volume_info or {}).get("level")
        remote.send_key_command("VOLUME_UP")
        await asyncio.sleep(1.0)
        after = (remote.volume_info or {}).get("level")
        remote.send_key_command("VOLUME_DOWN")
        ok("volumen reportado al cambiar", f"{before} -> {after}", after is not None and after != before)
    if ask("¿Abro YouTube con un deep link?"):
        remote.send_launch_app_command("https://www.youtube.com")
        await asyncio.sleep(3)
        ok("deep link YouTube", remote.current_app, "youtube" in (remote.current_app or ""))
    if ask("¿Pruebo escribir texto? Primero abre un buscador en la TV (ej. YouTube > Buscar)."):
        input("  Pon el cursor en el campo de búsqueda y presiona Enter aquí...")
        remote.send_text("hola desde fase 0")
        ok("texto (IME)", input("  ¿Apareció 'hola desde fase 0'? [s/N] ").strip().lower().startswith("s"))
    if ask("¿Abro una app por paquete (Google Play Store) para validar market://launch?"):
        remote.send_launch_app_command("com.android.vending")
        await asyncio.sleep(3)
        ok("abrir por paquete", remote.current_app, remote.current_app == "com.android.vending")

    remote.disconnect()
    if not args.no_adb:
        adb_probes(ip)


def write_report() -> None:
    OUT.mkdir(exist_ok=True)
    (OUT / "phase0-report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False, default=str))
    lines = [f"# Fase 0 — {report['started']}", "", f"IP: {report.get('ip')}", "", "| prueba | ok | valor | nota |", "| --- | --- | --- | --- |"]
    for k, v in report["checks"].items():
        val = json.dumps(v["value"], ensure_ascii=False, default=str)
        lines.append(f"| {k} | {'sí' if v['ok'] else 'NO'} | {val[:200]} | {v['note']} |")
    (OUT / "phase0-report.md").write_text("\n".join(lines) + "\n")
    print(f"\nReporte: {OUT / 'phase0-report.md'}")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("ip", nargs="?", help="IP de la TV (si no, se busca por mDNS)")
    p.add_argument("--no-adb", action="store_true", help="saltar las pruebas por ADB")
    args = p.parse_args()
    try:
        asyncio.run(run(args))
    except KeyboardInterrupt:
        print("\ninterrumpido")
    finally:
        write_report()
    return 0


if __name__ == "__main__":
    sys.exit(main())
