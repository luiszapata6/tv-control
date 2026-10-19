from __future__ import annotations

import pathlib
import sys

import pytest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from atv_sim import TvSimulator  # noqa: E402


@pytest.fixture
def sim(tmp_path):
    s = TvSimulator(ping_interval=0.5, state_dir=tmp_path / "tv").start()
    yield s
    s.stop()
