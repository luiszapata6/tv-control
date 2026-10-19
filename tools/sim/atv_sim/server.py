"""Simulated Android TV: pairing server (6467) and remote server (6466).

The behaviour mirrors what real TVs do as observed by the reference client
(androidtvremote2) so that our Dart client can be tested end to end:

* Pairing: pairing_request -> ack, options -> options, configuration -> ack,
  then the TV "shows" a 6 hex digit code. The client proves it saw the code by
  sending SHA-256(client n, e, server n, e, code[2:]); code[0:2] is the first
  byte of that hash.
* Remote: only certificates that completed pairing can connect (TLS handshake
  fails otherwise, like a real TV). The server sends remote_configure, expects
  the client's configure, sends set_active, then start/volume/app state and
  pings every few seconds.
"""

from __future__ import annotations

import json
import os
import pathlib
import secrets
import select
import socket
import threading
import time
from collections.abc import Callable
from dataclasses import asdict, dataclass, field
from urllib.parse import parse_qs, urlparse

from androidtvremote2.polo_pb2 import Options, OuterMessage
from androidtvremote2.remotemessage_pb2 import RemoteDirection, RemoteKeyCode, RemoteMessage
from cryptography import x509
from cryptography.hazmat.primitives import serialization
from OpenSSL import SSL

from .certs import fingerprint, make_server_cert, pairing_hash
from .framing import Deframer, frame

LAUNCHER = "com.google.android.tvlauncher"

# Feature bits (see androidtvremote2.remote.Feature).
F_PING, F_KEY, F_IME, F_VOICE, F_POWER, F_VOLUME, F_APP_LINK = 1, 2, 4, 8, 32, 64, 512
DEFAULT_FEATURES = F_PING | F_KEY | F_IME | F_VOICE | F_POWER | F_VOLUME | F_APP_LINK

KNOWN_LINKS = {
    "www.youtube.com": "com.google.android.youtube.tv",
    "youtube.com": "com.google.android.youtube.tv",
    "www.netflix.com": "com.netflix.ninja",
    "netflix.com": "com.netflix.ninja",
    "www.disneyplus.com": "com.disney.disneyplus",
    "app.primevideo.com": "com.amazon.amazonvideo.livingroom",
    "open.spotify.com": "com.spotify.tv.android",
}


@dataclass
class TvState:
    """Observable state of the simulated TV."""

    model: str = "65U6GA"
    vendor: str = "Hisense"
    name: str = "Hisense 65U6GA"
    mac: str = "AA:BB:CC:DD:EE:FF"
    is_on: bool = True
    volume_level: int = 18
    volume_max: int = 100
    muted: bool = False
    current_app: str = LAUNCHER
    ime_text: str = ""
    features: int = DEFAULT_FEATURES


@dataclass
class Event:
    kind: str
    data: dict = field(default_factory=dict)
    at: float = field(default_factory=time.time)


def package_for_link(link: str) -> str:
    parsed = urlparse(link)
    if parsed.scheme == "market":
        ids = parse_qs(parsed.query).get("id")
        if ids:
            return ids[0]
    host = parsed.netloc or parsed.path
    return KNOWN_LINKS.get(host, host or link)


class _Session:
    """One TLS connection, driven by a single thread (OpenSSL objects are not
    safe for concurrent reads and writes)."""

    def __init__(self, sim: TvSimulator, sock: socket.socket, ctx: SSL.Context, kind: str) -> None:
        self.sim = sim
        self.kind = kind
        self.sock = sock
        self.conn = SSL.Connection(ctx, sock)
        self.conn.set_accept_state()
        self.deframer = Deframer()
        self.outbox: list[bytes] = []
        self.lock = threading.Lock()
        self.closed = False
        self.peer: x509.Certificate | None = None
        # remote-session state
        self.client_features = 0
        self.started = False
        self.next_ping = 0.0
        self.unanswered_pings = 0
        self.ping_counter = 0

    # -- plumbing ---------------------------------------------------------
    def queue(self, payload: bytes) -> None:
        with self.lock:
            self.outbox.append(payload)

    def close(self) -> None:
        self.closed = True

    def _flush(self) -> None:
        with self.lock:
            pending, self.outbox = self.outbox, []
        for payload in pending:
            data = frame(payload)
            while data:
                try:
                    sent = self.conn.send(data)
                    data = data[sent:]
                except SSL.WantWriteError:
                    select.select([], [self.sock], [], 0.05)
                except SSL.WantReadError:
                    select.select([self.sock], [], [], 0.05)

    def _handshake(self) -> bool:
        deadline = time.time() + 5
        while time.time() < deadline:
            try:
                self.conn.do_handshake()
                cert = self.conn.get_peer_certificate()
                self.peer = cert.to_cryptography() if cert else None
                return True
            except SSL.WantReadError:
                select.select([self.sock], [], [], 0.05)
            except SSL.WantWriteError:
                select.select([], [self.sock], [], 0.05)
            except SSL.Error as exc:
                self.sim._event("tls_rejected", port=self.kind, error=str(exc))
                return False
        return False

    def run(self) -> None:
        self.sock.setblocking(False)
        try:
            if not self._handshake():
                return
            self.sim._register(self)
            self.on_open()
            while not self.closed and not self.sim._stopping.is_set():
                self._flush()
                self.tick()
                if self.conn.pending() == 0:
                    readable, _, _ = select.select([self.sock], [], [], 0.05)
                    if not readable:
                        continue
                try:
                    data = self.conn.recv(65536)
                except SSL.WantReadError:
                    continue
                except (SSL.ZeroReturnError, SSL.SysCallError, SSL.Error, OSError):
                    break
                if not data:
                    break
                for msg in self.deframer.feed(data):
                    self.handle(msg)
            self._flush()
        finally:
            self.sim._unregister(self)
            try:
                self.conn.shutdown()
            except Exception:  # noqa: BLE001 - best effort close
                pass
            self.sock.close()
            self.sim._event("disconnected", port=self.kind)

    # -- overridden by the protocol handlers ------------------------------
    def on_open(self) -> None: ...

    def tick(self) -> None: ...

    def handle(self, msg: bytes) -> None: ...


class _PairingSession(_Session):
    def on_open(self) -> None:
        self.sim._event("pairing_connected")

    def send(self, msg: OuterMessage) -> None:
        self.queue(msg.SerializeToString())

    @staticmethod
    def reply(status: int = OuterMessage.Status.STATUS_OK) -> OuterMessage:
        out = OuterMessage()
        out.protocol_version = 2
        out.status = status
        return out

    def handle(self, raw: bytes) -> None:
        msg = OuterMessage()
        msg.ParseFromString(raw)
        if msg.status != OuterMessage.Status.STATUS_OK:
            self.close()
            return
        out = self.reply()
        if msg.HasField("pairing_request"):
            self.sim._event(
                "pairing_request",
                client_name=msg.pairing_request.client_name,
                service_name=msg.pairing_request.service_name,
            )
            out.pairing_request_ack.server_name = self.sim.state.name
        elif msg.HasField("options"):
            enc = out.options.input_encodings.add()
            enc.type = Options.Encoding.ENCODING_TYPE_HEXADECIMAL
            enc.symbol_length = 6
            out.options.preferred_role = Options.RoleType.ROLE_TYPE_INPUT
        elif msg.HasField("configuration"):
            out.configuration_ack.SetInParent()
            self.send(out)
            self.sim._show_code(self)
            return
        elif msg.HasField("secret"):
            expected = self.sim._expected_secret(self)
            if expected is not None and msg.secret.secret == expected:
                out.secret_ack.secret = expected
                self.send(out)
                self.sim._mark_paired(self.peer)
            else:
                self.sim._event("pairing_failed", reason="bad_secret")
                self.send(self.reply(OuterMessage.Status.STATUS_BAD_SECRET))
                self.close()
            return
        else:
            self.send(self.reply(OuterMessage.Status.STATUS_BAD_CONFIGURATION))
            self.close()
            return
        self.send(out)


class _RemoteSession(_Session):
    def on_open(self) -> None:
        self.sim._event("remote_connected")
        st = self.sim.state
        msg = RemoteMessage()
        msg.remote_configure.code1 = st.features
        info = msg.remote_configure.device_info
        info.model = st.model
        info.vendor = st.vendor
        info.unknown1 = 1
        info.unknown2 = "1"
        info.package_name = "com.google.android.tv.remote.service"
        info.app_version = "5.2.473254133"
        self.send(msg)

    def send(self, msg: RemoteMessage) -> None:
        self.queue(msg.SerializeToString())

    def tick(self) -> None:
        if not self.started or self.sim.ping_interval <= 0:
            return
        now = time.time()
        if now < self.next_ping:
            return
        if self.unanswered_pings >= 3:
            self.sim._event("ping_timeout")
            self.close()
            return
        self.ping_counter += 1
        self.unanswered_pings += 1
        ping = RemoteMessage()
        ping.remote_ping_request.val1 = self.ping_counter
        ping.remote_ping_request.val2 = 1
        self.send(ping)
        self.next_ping = now + self.sim.ping_interval

    def push_state(self) -> None:
        st = self.sim.state
        start = RemoteMessage()
        start.remote_start.started = st.is_on
        self.send(start)
        self.push_volume()
        if self.client_features & F_IME:
            self.push_app()

    def push_volume(self) -> None:
        st = self.sim.state
        vol = RemoteMessage()
        vol.remote_set_volume_level.volume_max = st.volume_max
        vol.remote_set_volume_level.volume_level = st.volume_level
        vol.remote_set_volume_level.volume_muted = st.muted
        vol.remote_set_volume_level.player_model = st.model
        self.send(vol)

    def push_app(self) -> None:
        msg = RemoteMessage()
        msg.remote_ime_key_inject.app_info.app_package = self.sim.state.current_app
        self.send(msg)
        batch = RemoteMessage()
        batch.remote_ime_batch_edit.ime_counter = self.sim.ime_counter
        batch.remote_ime_batch_edit.field_counter = self.sim.field_counter
        self.send(batch)

    def push_power(self) -> None:
        msg = RemoteMessage()
        msg.remote_start.started = self.sim.state.is_on
        self.send(msg)

    def handle(self, raw: bytes) -> None:
        msg = RemoteMessage()
        msg.ParseFromString(raw)
        sim = self.sim
        if msg.HasField("remote_configure"):
            self.client_features = msg.remote_configure.code1
            sim._event(
                "client_configure",
                features=self.client_features,
                package_name=msg.remote_configure.device_info.package_name,
            )
            active = RemoteMessage()
            active.remote_set_active.active = 622
            self.send(active)
        elif msg.HasField("remote_set_active"):
            sim._event("client_set_active", active=msg.remote_set_active.active)
            self.started = True
            self.next_ping = time.time() + sim.ping_interval
            self.push_state()
            sim._event("remote_ready")
        elif msg.HasField("remote_ping_response"):
            self.unanswered_pings = 0
            sim._event("pong", val1=msg.remote_ping_response.val1)
        elif msg.HasField("remote_key_inject"):
            key = RemoteKeyCode.Name(msg.remote_key_inject.key_code) if msg.remote_key_inject.key_code in RemoteKeyCode.values() else str(msg.remote_key_inject.key_code)
            direction = RemoteDirection.Name(msg.remote_key_inject.direction)
            sim._event("key", key=key, direction=direction)
            if direction in ("SHORT", "START_LONG"):
                sim._apply_key(key)
        elif msg.HasField("remote_app_link_launch_request"):
            link = msg.remote_app_link_launch_request.app_link
            sim._event("app_link", link=link)
            sim._set_app(package_for_link(link))
        elif msg.HasField("remote_ime_batch_edit"):
            edit = msg.remote_ime_batch_edit
            text = edit.edit_info[0].text_field_status.value if edit.edit_info else ""
            sim.state.ime_text = text
            sim._event("text", text=text, ime_counter=edit.ime_counter, field_counter=edit.field_counter)
        elif msg.HasField("remote_voice_begin"):
            sim._event("voice_begin", session_id=msg.remote_voice_begin.session_id)
        elif msg.HasField("remote_voice_payload"):
            sim._event("voice_payload", size=len(msg.remote_voice_payload.samples))
        elif msg.HasField("remote_voice_end"):
            sim._event("voice_end")
        else:
            sim._event("unhandled", fields=[f.name for f, _ in msg.ListFields()])


class TvSimulator:
    """Run a simulated TV on two TCP ports."""

    def __init__(
        self,
        host: str = "127.0.0.1",
        pairing_port: int = 0,
        remote_port: int = 0,
        state: TvState | None = None,
        state_dir: str | os.PathLike[str] | None = None,
        ping_interval: float = 5.0,
        code_file: str | os.PathLike[str] | None = None,
        events_file: str | os.PathLike[str] | None = None,
        on_event: Callable[[Event], None] | None = None,
    ) -> None:
        self.host = host
        self.state = state or TvState()
        self.ping_interval = ping_interval
        self.code_file = pathlib.Path(code_file) if code_file else None
        self.events_file = pathlib.Path(events_file) if events_file else None
        self.state_dir = pathlib.Path(state_dir) if state_dir else None
        self.on_event = on_event
        self.events: list[Event] = []
        self.pairing_code: str | None = None
        self.ime_counter = 1
        self.field_counter = 1
        self._requested_ports = (pairing_port, remote_port)
        self.pairing_port = 0
        self.remote_port = 0
        self._paired: set[str] = set()
        self._pending_secret: dict[int, bytes] = {}
        self._sessions: list[_Session] = []
        self._lock = threading.RLock()
        self._cond = threading.Condition(self._lock)
        self._stopping = threading.Event()
        self._threads: list[threading.Thread] = []
        self._sockets: list[socket.socket] = []
        self._cert_pem, self._key_pem = self._load_or_make_cert()
        self.server_cert = x509.load_pem_x509_certificate(self._cert_pem)
        self._load_paired()

    # -- persistence -------------------------------------------------------
    def _load_or_make_cert(self) -> tuple[bytes, bytes]:
        if self.state_dir:
            cert_path, key_path = self.state_dir / "server.pem", self.state_dir / "server.key"
            if cert_path.exists() and key_path.exists():
                return cert_path.read_bytes(), key_path.read_bytes()
        cert, key = make_server_cert(self.state.model, self.state.name, self.state.mac)
        if self.state_dir:
            self.state_dir.mkdir(parents=True, exist_ok=True)
            (self.state_dir / "server.pem").write_bytes(cert)
            (self.state_dir / "server.key").write_bytes(key)
        return cert, key

    def _load_paired(self) -> None:
        if self.state_dir and (self.state_dir / "paired.json").exists():
            self._paired = set(json.loads((self.state_dir / "paired.json").read_text()))

    def _save_paired(self) -> None:
        if self.state_dir:
            (self.state_dir / "paired.json").write_text(json.dumps(sorted(self._paired)))

    # -- lifecycle -----------------------------------------------------------
    def _context(self, require_paired: bool) -> SSL.Context:
        ctx = SSL.Context(SSL.TLS_SERVER_METHOD)
        ctx.use_certificate(self.server_cert)
        ctx.use_privatekey(serialization.load_pem_private_key(self._key_pem, password=None))

        def verify(_conn, cert, _errno, depth, _ok) -> bool:
            if not require_paired or depth > 0:
                return True
            return fingerprint(cert.to_cryptography()) in self._paired

        ctx.set_verify(SSL.VERIFY_PEER | SSL.VERIFY_FAIL_IF_NO_PEER_CERT, verify)
        return ctx

    def start(self) -> TvSimulator:
        specs = (
            ("pairing", self._requested_ports[0], self._context(False), _PairingSession),
            ("remote", self._requested_ports[1], self._context(True), _RemoteSession),
        )
        for kind, port, ctx, cls in specs:
            srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            srv.bind((self.host, port))
            srv.listen(8)
            srv.settimeout(0.2)
            self._sockets.append(srv)
            if kind == "pairing":
                self.pairing_port = srv.getsockname()[1]
            else:
                self.remote_port = srv.getsockname()[1]
            t = threading.Thread(target=self._accept_loop, args=(srv, ctx, cls, kind), daemon=True, name=f"sim-{kind}")
            t.start()
            self._threads.append(t)
        self._event("started", pairing_port=self.pairing_port, remote_port=self.remote_port)
        return self

    def stop(self) -> None:
        self._stopping.set()
        for s in self._sockets:
            s.close()
        for t in self._threads:
            t.join(timeout=2)

    def __enter__(self) -> TvSimulator:
        return self.start()

    def __exit__(self, *exc: object) -> None:
        self.stop()

    def _accept_loop(self, srv: socket.socket, ctx: SSL.Context, cls: type[_Session], kind: str) -> None:
        while not self._stopping.is_set():
            try:
                sock, _ = srv.accept()
            except (TimeoutError, socket.timeout):
                continue
            except OSError:
                return
            session = cls(self, sock, ctx, kind)
            threading.Thread(target=session.run, daemon=True, name=f"sim-{kind}-conn").start()

    # -- sessions ------------------------------------------------------------
    def _register(self, s: _Session) -> None:
        with self._lock:
            self._sessions.append(s)

    def _unregister(self, s: _Session) -> None:
        with self._lock:
            if s in self._sessions:
                self._sessions.remove(s)

    def _remote_sessions(self) -> list[_RemoteSession]:
        with self._lock:
            return [s for s in self._sessions if isinstance(s, _RemoteSession) and s.started]

    def disconnect_all(self) -> None:
        with self._lock:
            for s in self._sessions:
                s.close()

    # -- events ----------------------------------------------------------------
    def _event(self, kind: str, **data: object) -> None:
        ev = Event(kind, dict(data))
        with self._cond:
            self.events.append(ev)
            self._cond.notify_all()
        if self.events_file:
            with self.events_file.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps({"kind": kind, **data, "at": ev.at}) + "\n")
        if self.on_event:
            self.on_event(ev)

    def wait_for(self, kind: str, timeout: float = 5.0, **match: object) -> Event:
        """Block until an event of [kind] whose data contains [match] arrives."""
        deadline = time.time() + timeout
        with self._cond:
            while True:
                for ev in self.events:
                    if ev.kind == kind and all(ev.data.get(k) == v for k, v in match.items()):
                        return ev
                remaining = deadline - time.time()
                if remaining <= 0:
                    raise TimeoutError(f"no {kind} event matching {match}; got {[e.kind for e in self.events]}")
                self._cond.wait(remaining)

    def events_of(self, kind: str) -> list[Event]:
        with self._lock:
            return [e for e in self.events if e.kind == kind]

    # -- pairing -------------------------------------------------------------
    def _show_code(self, session: _Session) -> None:
        if session.peer is None:
            session.close()
            return
        nonce = secrets.token_bytes(2)
        digest = pairing_hash(session.peer, self.server_cert, nonce)
        code = f"{digest[0]:02X}{nonce.hex().upper()}"
        with self._lock:
            self._pending_secret[id(session)] = digest
            self.pairing_code = code
        if self.code_file:
            self.code_file.write_text(code)
        self._event("pairing_code", code=code)

    def _expected_secret(self, session: _Session) -> bytes | None:
        with self._lock:
            return self._pending_secret.pop(id(session), None)

    def _mark_paired(self, cert: x509.Certificate | None) -> None:
        if cert is None:
            return
        with self._lock:
            self._paired.add(fingerprint(cert))
            self._save_paired()
        self._event("paired", fingerprint=fingerprint(cert))

    def is_paired(self, cert: x509.Certificate) -> bool:
        return fingerprint(cert) in self._paired

    def unpair_all(self) -> None:
        with self._lock:
            self._paired.clear()
            self._save_paired()

    # -- TV behaviour --------------------------------------------------------
    def _apply_key(self, key: str) -> None:
        st = self.state
        if key == "KEYCODE_VOLUME_UP":
            self.set_volume(min(st.volume_max, st.volume_level + 1), muted=False)
        elif key == "KEYCODE_VOLUME_DOWN":
            self.set_volume(max(0, st.volume_level - 1), muted=False)
        elif key in ("KEYCODE_VOLUME_MUTE", "KEYCODE_MUTE"):
            self.set_volume(st.volume_level, muted=not st.muted)
        elif key in ("KEYCODE_POWER", "KEYCODE_TV_POWER"):
            self.set_power(not st.is_on)
        elif key == "KEYCODE_SLEEP":
            self.set_power(False)
        elif key == "KEYCODE_WAKEUP":
            self.set_power(True)
        elif key == "KEYCODE_HOME":
            self._set_app(LAUNCHER)

    def set_volume(self, level: int, muted: bool | None = None) -> None:
        self.state.volume_level = level
        if muted is not None:
            self.state.muted = muted
        for s in self._remote_sessions():
            s.push_volume()

    def set_power(self, on: bool) -> None:
        self.state.is_on = on
        for s in self._remote_sessions():
            s.push_power()

    def _set_app(self, package: str) -> None:
        self.state.current_app = package
        self.ime_counter += 1
        for s in self._remote_sessions():
            if s.client_features & F_IME:
                s.push_app()

    def snapshot(self) -> dict:
        return asdict(self.state)
