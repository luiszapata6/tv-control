"""Certificates for the simulated TV and helpers shared with the tests."""

from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID


def make_server_cert(model: str, name: str, mac: str) -> tuple[bytes, bytes]:
    """Self-signed RSA certificate shaped like a real Android TV's.

    Real TVs use a subject like ``CN=atvremote/<board>/<device>/<name>/<MAC>``;
    clients parse the friendly name and MAC address (for Wake-on-LAN) from it.
    """
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    subject = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, f"atvremote/{model}/{model}/{name}/{mac}")])
    now = datetime.now(timezone.utc)
    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(subject)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(now - timedelta(days=1))
        .not_valid_after(now + timedelta(days=3650))
        .sign(key, hashes.SHA256())
    )
    return (
        cert.public_bytes(serialization.Encoding.PEM),
        key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.TraditionalOpenSSL,
            serialization.NoEncryption(),
        ),
    )


def rsa_numbers(cert: x509.Certificate) -> tuple[int, int]:
    numbers = cert.public_key().public_numbers()  # type: ignore[union-attr]
    return numbers.n, numbers.e


def unsigned_bytes(value: int) -> bytes:
    """Minimal big-endian encoding, as ``bytes.fromhex(f"{value:X}")`` in the reference."""
    return value.to_bytes(max(1, (value.bit_length() + 7) // 8), "big")


def pairing_hash(client: x509.Certificate, server: x509.Certificate, nonce: bytes) -> bytes:
    """SHA-256 over client modulus, client exponent, server modulus, server exponent, nonce."""
    cn, ce = rsa_numbers(client)
    sn, se = rsa_numbers(server)
    h = hashlib.sha256()
    for part in (unsigned_bytes(cn), unsigned_bytes(ce), unsigned_bytes(sn), unsigned_bytes(se), nonce):
        h.update(part)
    return h.digest()


def fingerprint(cert: x509.Certificate) -> str:
    return cert.fingerprint(hashes.SHA256()).hex()
