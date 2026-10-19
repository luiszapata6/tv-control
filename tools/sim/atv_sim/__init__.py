"""A simulated Android TV that speaks the Android TV Remote v2 protocol.

Used to test the Dart client (packages/atv_remote) and the iPhone app without a
real TV. It is validated against the reference Python client (androidtvremote2)
in tools/sim/tests.
"""

from .server import TvSimulator, TvState

__all__ = ["TvSimulator", "TvState"]
