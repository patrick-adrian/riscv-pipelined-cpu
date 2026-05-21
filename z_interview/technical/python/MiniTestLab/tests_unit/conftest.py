"""Shared pytest fixtures.

`conftest.py` is auto-discovered by pytest — anything defined here
is available to tests in the same directory tree, without imports.

Why use fixtures?
    - Centralize setup/teardown.
    - Encourage tests to declare their dependencies explicitly.
    - Free for parametrization, scope control (session/module/function),
      and dependency-injection-style composition.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Make the project importable regardless of where pytest is invoked from.
_REPO_ROOT = Path(__file__).resolve().parent.parent
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))


@pytest.fixture()
def sample_log_path() -> Path:
    """Return the path to the canned sample log file."""
    return _REPO_ROOT / "sample_logs" / "device.log"


@pytest.fixture()
def tmp_reports_dir(tmp_path: Path) -> Path:
    """A per-test isolated reports directory."""
    out = tmp_path / "reports"
    out.mkdir()
    return out
