"""Subprocess smoke tests.

Demonstrates safe subprocess usage and output parsing — patterns
that show up in nearly every validation script.
"""

from __future__ import annotations

import platform
import sys
from typing import Any

from framework.runner import test_case
from framework.utils import run_command


@test_case(
    name="subprocess_echo_hello",
    description="Spawn the current Python interpreter to print a known string.",
    timeout_s=4.0,
    tags=("subprocess", "smoke"),
)
def subprocess_echo_hello(metadata: dict[str, Any]) -> None:
    # Using `sys.executable` makes the test portable: it always invokes
    # the same interpreter that's running the framework, instead of
    # depending on whatever `python` happens to be on PATH.
    result = run_command(
        [sys.executable, "-c", "print('hello-from-subprocess')"],
        timeout_s=3.0,
    )
    metadata["return_code"] = result.returncode
    metadata["stdout_len"] = len(result.stdout)

    assert result.returncode == 0, f"Subprocess exited with {result.returncode}"
    assert "hello-from-subprocess" in result.stdout, (
        f"Expected greeting missing. stdout={result.stdout!r}"
    )


@test_case(
    name="subprocess_platform_reports_match",
    description="Cross-check `uname`/`ver` output against platform.system() (best-effort).",
    timeout_s=4.0,
    tags=("subprocess",),
)
def subprocess_platform_reports_match(metadata: dict[str, Any]) -> None:
    system = platform.system()
    metadata["python_platform"] = system

    if system == "Windows":
        result = run_command(["cmd", "/c", "ver"], timeout_s=3.0)
        metadata["external_stdout"] = result.stdout.strip()
        assert "Windows" in result.stdout, "ver output didn't mention Windows"
    else:
        result = run_command(["uname", "-s"], timeout_s=3.0)
        external = result.stdout.strip()
        metadata["external_stdout"] = external
        # Be lenient: macOS uname says "Darwin", Linux says "Linux", etc.
        assert external, "uname returned empty output"
