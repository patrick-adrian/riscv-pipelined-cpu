"""Shared utilities: decorators, subprocess helpers, config loading.

This module is intentionally small. The temptation in real projects
is to grow `utils.py` into a junk drawer. Resist it: if something
grows past ~50 lines or gains its own state, give it its own module.

Why decorators here?
    - `retry` and `timed` are cross-cutting concerns reused across
      tests. Decorators keep the call sites clean.
"""

from __future__ import annotations

import functools
import json
import os
import shutil
import subprocess
import time
from pathlib import Path
from typing import Any, Callable, Iterator, Optional, TypeVar

from framework.exceptions import ConfigError, TestExecutionError
from framework.logger import get_logger

_logger = get_logger(__name__)

# TypeVar lets `retry` preserve the wrapped function's signature in
# static type-checker output. Without this, mypy would see
# `Callable[..., Any]` and lose type information.
F = TypeVar("F", bound=Callable[..., Any])


def retry(
    *,
    attempts: int = 3,
    delay_s: float = 0.5,
    backoff: float = 2.0,
    exceptions: tuple[type[BaseException], ...] = (Exception,),
) -> Callable[[F], F]:
    """Retry a flaky function with exponential backoff.

    Interview talking point:
        "Retry isn't a fix for bugs — it's a fix for *transient*
         failures: network blips, races against external services,
         shared-resource contention. Always cap attempts and never
         retry on non-idempotent operations."

    Args:
        attempts: Maximum number of tries (must be >= 1).
        delay_s: Initial sleep between attempts.
        backoff: Multiplier applied to delay after each failure.
        exceptions: Tuple of exception types that trigger a retry.
            Anything else propagates immediately.
    """
    if attempts < 1:
        raise ValueError("attempts must be >= 1")

    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            current_delay = delay_s
            last_exc: Optional[BaseException] = None
            for attempt in range(1, attempts + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as exc:
                    last_exc = exc
                    if attempt == attempts:
                        break
                    _logger.warning(
                        "%s failed on attempt %d/%d: %s. Retrying in %.2fs...",
                        func.__name__, attempt, attempts, exc, current_delay,
                    )
                    time.sleep(current_delay)
                    current_delay *= backoff
            assert last_exc is not None  # for type-checker; loop ran at least once
            raise last_exc

        return wrapper  # type: ignore[return-value]

    return decorator


def timed(func: F) -> F:
    """Log how long a function takes to run.

    Lightweight cousin of the runner's own timing — useful for debugging
    individual helpers without standing up the full test harness.
    """

    @functools.wraps(func)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        start = time.perf_counter()
        try:
            return func(*args, **kwargs)
        finally:
            elapsed = time.perf_counter() - start
            _logger.debug("%s ran in %.4fs", func.__name__, elapsed)

    return wrapper  # type: ignore[return-value]


def run_command(
    cmd: list[str],
    *,
    timeout_s: float = 10.0,
    check: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Run a subprocess safely and return its CompletedProcess.

    Security and correctness notes:
        - We require `cmd` to be a `list[str]`, never a single string.
          That keeps `shell=False` (the default) safe from shell
          injection (`"rm -rf /; ls"` won't be interpreted by sh).
        - `text=True` decodes stdout/stderr using the platform encoding,
          giving us strings instead of bytes.
        - `timeout` prevents hangs from blocking the whole suite.

    Interview talking point:
        "Never pass user input to subprocess with shell=True. Use a
         list of arguments and let the OS execve the binary directly."
    """
    if not cmd:
        raise ValueError("cmd must be a non-empty list of strings")
    if shutil.which(cmd[0]) is None:
        raise TestExecutionError(
            test_name=cmd[0],
            message=f"Required executable '{cmd[0]}' not found on PATH",
        )

    _logger.debug("Running command: %s (timeout=%.1fs)", cmd, timeout_s)
    try:
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            check=check,
            shell=False,
        )
    except subprocess.TimeoutExpired as exc:
        # Re-raise as our typed exception so the runner can classify it.
        raise TestExecutionError(
            test_name=cmd[0],
            message=f"Command timed out after {timeout_s:.1f}s",
            cause=exc,
        ) from exc


def load_json_config(path: Path) -> dict[str, Any]:
    """Load a JSON config file with friendly error messages.

    Why a wrapper?
        `json.load` raises `JSONDecodeError` with a line number but
        no file context. Wrapping it lets us include the path so
        debugging stops being a treasure hunt.
    """
    if not path.exists():
        raise ConfigError(f"Config file not found: {path}")
    try:
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError(f"Config root must be a JSON object, got {type(data).__name__}")
    return data


def env_flag(name: str, default: bool = False) -> bool:
    """Read a boolean-ish environment variable.

    Accepts 1/0, true/false, yes/no (case-insensitive).
    Useful for opt-in features without adding more CLI flags.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


def chunked(seq: list[Any], size: int) -> Iterator[list[Any]]:
    """Yield successive chunks of `seq` of length `size`.

    Generator example: returns an Iterator instead of materializing
    a list of lists. Useful when the caller might process huge
    sequences (log lines, packet captures) lazily.
    """
    if size <= 0:
        raise ValueError("size must be > 0")
    for i in range(0, len(seq), size):
        yield seq[i:i + size]
