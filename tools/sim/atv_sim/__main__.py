"""Run the simulated TV from the command line.

    python -m atv_sim --pairing-port 6467 --remote-port 6466 \
        --code-file /tmp/code.txt --events-file /tmp/events.jsonl

Prints one JSON line with the bound ports on start, then runs until killed.
"""

from __future__ import annotations

import argparse
import json
import signal
import sys
import threading

from .server import TvSimulator, TvState


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="atv_sim", description=__doc__)
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--pairing-port", type=int, default=6467)
    p.add_argument("--remote-port", type=int, default=6466)
    p.add_argument("--state-dir", help="keep the server certificate and paired clients here")
    p.add_argument("--code-file", help="write the current pairing code to this file")
    p.add_argument("--events-file", help="append received events as JSON lines")
    p.add_argument("--ping-interval", type=float, default=5.0)
    p.add_argument("--name", default="Hisense 65U6GA")
    p.add_argument(
        "--control-stdin",
        action="store_true",
        help="read commands from stdin: volume N | mute on|off | power on|off | app PKG | disconnect | unpair | quit",
    )
    args = p.parse_args(argv)

    sim = TvSimulator(
        host=args.host,
        pairing_port=args.pairing_port,
        remote_port=args.remote_port,
        state=TvState(name=args.name),
        state_dir=args.state_dir,
        ping_interval=args.ping_interval,
        code_file=args.code_file,
        events_file=args.events_file,
    ).start()
    print(json.dumps({"pairing_port": sim.pairing_port, "remote_port": sim.remote_port}), flush=True)

    done = threading.Event()
    signal.signal(signal.SIGTERM, lambda *_: done.set())
    signal.signal(signal.SIGINT, lambda *_: done.set())
    if args.control_stdin:
        threading.Thread(target=_control_loop, args=(sim, done), daemon=True).start()
    done.wait()
    sim.stop()
    return 0


def _control_loop(sim: TvSimulator, done: threading.Event) -> None:
    for line in sys.stdin:
        cmd, *rest = line.split() or [""]
        arg = rest[0] if rest else ""
        if cmd == "volume":
            sim.set_volume(int(arg))
        elif cmd == "mute":
            sim.set_volume(sim.state.volume_level, muted=arg == "on")
        elif cmd == "power":
            sim.set_power(arg == "on")
        elif cmd == "app":
            sim._set_app(arg)
        elif cmd == "disconnect":
            sim.disconnect_all()
        elif cmd == "unpair":
            sim.unpair_all()
        elif cmd == "quit":
            break
        print(json.dumps({"ack": cmd}), flush=True)
    done.set()


if __name__ == "__main__":
    sys.exit(main())
