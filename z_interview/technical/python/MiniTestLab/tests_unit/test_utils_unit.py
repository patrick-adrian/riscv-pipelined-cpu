"""Unit tests for `framework.utils`."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from framework.exceptions import ConfigError
from framework.utils import chunked, env_flag, load_json_config, retry


def test_chunked_basic() -> None:
    chunks = list(chunked([1, 2, 3, 4, 5], 2))
    assert chunks == [[1, 2], [3, 4], [5]]


def test_chunked_invalid_size() -> None:
    with pytest.raises(ValueError):
        list(chunked([1, 2, 3], 0))


def test_env_flag(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("FLAG", "true")
    assert env_flag("FLAG") is True
    monkeypatch.setenv("FLAG", "off")
    assert env_flag("FLAG") is False
    monkeypatch.delenv("FLAG", raising=False)
    assert env_flag("FLAG", default=True) is True


def test_load_json_config_missing(tmp_path: Path) -> None:
    with pytest.raises(ConfigError):
        load_json_config(tmp_path / "missing.json")


def test_load_json_config_bad_json(tmp_path: Path) -> None:
    bad = tmp_path / "bad.json"
    bad.write_text("{not json}")
    with pytest.raises(ConfigError):
        load_json_config(bad)


def test_load_json_config_must_be_object(tmp_path: Path) -> None:
    arr = tmp_path / "arr.json"
    arr.write_text("[1, 2, 3]")
    with pytest.raises(ConfigError):
        load_json_config(arr)


def test_retry_eventually_succeeds() -> None:
    calls = {"n": 0}

    @retry(attempts=3, delay_s=0.0)
    def flaky() -> str:
        calls["n"] += 1
        if calls["n"] < 3:
            raise RuntimeError("not yet")
        return "ok"

    assert flaky() == "ok"
    assert calls["n"] == 3


def test_retry_gives_up() -> None:
    @retry(attempts=2, delay_s=0.0)
    def always_fails() -> None:
        raise RuntimeError("nope")

    with pytest.raises(RuntimeError, match="nope"):
        always_fails()


def test_retry_does_not_swallow_unlisted_exceptions() -> None:
    @retry(attempts=3, delay_s=0.0, exceptions=(ValueError,))
    def raises_runtime() -> None:
        raise RuntimeError("not in retry list")

    with pytest.raises(RuntimeError):
        raises_runtime()
