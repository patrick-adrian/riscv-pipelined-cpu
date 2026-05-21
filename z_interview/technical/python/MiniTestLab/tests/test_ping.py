"""Network reachability tests using the system `ping` binary.

Why exercise subprocess here?
    Network checks are the single most common smoke test in
    validation/QA work. They also exercise:
        - cross-platform binary differences (Linux vs macOS vs Windows)
        - subprocess argument lists (NEVER shell=True with user input)
        - output parsing with regex
"""

from __future__ import annotations

import platform
import re
from typing import Any

from framework.runner import test_case
from framework.utils import retry, run_command


_LATENCY_RE = re.compile(
    r"time[=<]\s*(?P<ms>\d+(?:\.\d+)?)\s*ms",
    re.IGNORECASE,
)


def _ping_args(host: str, count: int) -> list[str]:
    """Return ping arguments appropriate for the current OS.

    Windows uses `-n` and `-w` (ms), POSIX uses `-c` and `-W` (s).
    Hard-coding one flavor is a classic CI-on-my-machine bug.
    """
    if platform.system() == "Windows":
        return ["ping", "-n", str(count), "-w", "2000", host]
    return ["ping", "-c", str(count), "-W", "2", host]


@test_case(
    name="ping_localhost",
    description="Verify localhost responds to ICMP echo (basic stack health).",
    timeout_s=8.0,
    tags=("network", "smoke"),
)
@retry(attempts=2, delay_s=0.5, exceptions=(AssertionError,))
def ping_localhost(metadata: dict[str, Any]) -> None:
    result = run_command(_ping_args("127.0.0.1", count=2), timeout_s=6.0)
    assert result.returncode == 0, (
        f"ping returned {result.returncode}\nstdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}"
    )

    latencies = [float(m.group("ms")) for m in _LATENCY_RE.finditer(result.stdout)]
    if latencies:
        metadata["latency_ms_min"] = min(latencies)
        metadata["latency_ms_max"] = max(latencies)
        metadata["latency_ms_avg"] = sum(latencies) / len(latencies)
        metadata["samples"] = len(latencies)


@test_case(
    name="ping_loopback_v6",
    description="Verify IPv6 loopback (::1) responds. Skipped gracefully if unsupported.",
    timeout_s=6.0,
    tags=("network",),
)
def ping_loopback_v6(metadata: dict[str, Any]) -> None:
    args = _ping_args("::1", count=1)
    if platform.system() != "Windows":
        # On Linux/macOS, `ping` may or may not handle v6. Prefer ping6 when available.
        args[0] = "ping"  # most modern coreutils ping handles -6 transparently
        args.insert(1, "-6")

    try:
        result = run_command(args, timeout_s=4.0)
    except Exception as exc:
        # Treat "no IPv6 stack" as a soft fail with a descriptive message.
        # In a richer framework we'd raise a SkipTest exception; here we
        # surface it as a FAIL with context so it's visible in reports.
        raise AssertionError(f"IPv6 ping unavailable: {exc}") from exc

    metadata["return_code"] = result.returncode
    assert result.returncode == 0, "IPv6 loopback did not respond"
