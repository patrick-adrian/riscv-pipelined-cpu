"""CPU sanity tests.

Validation engineers love CPU-bound smoke tests because they catch:
    - thermal throttling on first boot
    - missing cores after a firmware update
    - hot-plug regressions
"""

from __future__ import annotations

import os
import time
from typing import Any

from framework.runner import test_case


@test_case(
    name="cpu_count_nonzero",
    description="The OS must report at least one usable CPU.",
    timeout_s=2.0,
    tags=("cpu", "smoke"),
)
def cpu_count_nonzero(metadata: dict[str, Any]) -> None:
    count = os.cpu_count()
    metadata["cpu_count"] = count
    assert count is not None and count >= 1, f"Unexpected cpu_count={count!r}"


@test_case(
    name="cpu_can_compute",
    description="Run a small compute kernel and assert it completes in reasonable time.",
    timeout_s=5.0,
    tags=("cpu", "perf"),
)
def cpu_can_compute(metadata: dict[str, Any]) -> None:
    # Toy compute kernel; replace with `dgemm`/`stress-ng`/etc. in a
    # real validation suite. The point is to demonstrate the *shape*
    # of a perf test that records measurements into metadata.
    iterations = 200_000
    start = time.perf_counter()
    acc = 0
    for i in range(iterations):
        acc += (i * i) % 7
    elapsed = time.perf_counter() - start

    metadata["iterations"] = iterations
    metadata["compute_runtime_s"] = round(elapsed, 6)
    metadata["acc_checksum"] = acc

    assert elapsed < 2.0, f"Compute kernel too slow: {elapsed:.3f}s"
    assert acc > 0, "Compute kernel produced no work"
