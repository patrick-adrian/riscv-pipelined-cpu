"""Data models for tests, results, and suite summaries.

Why dataclasses?
    - Auto-generated `__init__`, `__repr__`, `__eq__` reduce boilerplate.
    - `frozen=True` gives us cheap immutability for result objects,
      which is great for thread-safety and avoiding spooky mutation
      across the reporting pipeline.
    - `asdict()` makes JSON/CSV serialization trivial.

Why enums?
    - Magic strings ("PASS", "FAIL", "pass", "Passed") are a classic
      source of bugs. Enums centralize the vocabulary and let static
      type checkers (mypy, pyright) catch typos.

Interview talking point:
    "Use enums for closed sets of values, dataclasses for plain data,
     and Protocols/ABCs for behavior contracts."
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Callable, Optional


class TestStatus(str, Enum):
    """Closed set of result statuses a test can finish in.

    Inheriting from `str` lets the enum serialize cleanly to JSON
    without a custom encoder — `json.dumps(TestStatus.PASS)` works.
    """

    PASS = "PASS"
    FAIL = "FAIL"
    ERROR = "ERROR"      # framework-level failure (e.g., bad config)
    TIMEOUT = "TIMEOUT"
    SKIPPED = "SKIPPED"

    @property
    def is_successful(self) -> bool:
        """True if this status counts as a successful outcome."""
        return self is TestStatus.PASS


@dataclass(frozen=True)
class TestCase:
    """Static description of a test (the *what*, not the *result*).

    Frozen because once a test is registered, its definition should
    not mutate at runtime.
    """

    name: str
    func: Callable[..., None]
    description: str = ""
    timeout_s: float = 10.0
    tags: tuple[str, ...] = field(default_factory=tuple)


@dataclass(frozen=True)
class TestResult:
    """Outcome of a single test execution.

    Notes:
        - `timestamp` is recorded in UTC. Mixing local-time timestamps
          across CI runners on different machines is a classic source
          of confusing reports.
        - `error_message` is `Optional[str]`; `None` means "no error".
        - `metadata` is a free-form dict for test-specific extras
          (latency_ms, packet_loss, cpu_pct, ...).
    """

    name: str
    status: TestStatus
    runtime_s: float
    timestamp: str
    error_message: Optional[str] = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @staticmethod
    def utcnow_iso() -> str:
        """Return ISO-8601 UTC timestamp suitable for reports."""
        return datetime.now(timezone.utc).isoformat(timespec="seconds")

    def to_dict(self) -> dict[str, Any]:
        """Serialize to a plain dict (JSON-friendly)."""
        return asdict(self)


@dataclass(frozen=True)
class TestSuiteSummary:
    """Aggregate view of a full suite run.

    Useful for CI exit-code logic, dashboards, and quick CLI summaries.
    """

    total: int
    passed: int
    failed: int
    errored: int
    timed_out: int
    skipped: int
    total_runtime_s: float

    @classmethod
    def from_results(cls, results: list[TestResult]) -> "TestSuiteSummary":
        """Build a summary from an iterable of results.

        Using a classmethod keeps the aggregation logic next to the
        data type that owns it (cohesion > scattered helpers).
        """
        counts = {s: 0 for s in TestStatus}
        for r in results:
            counts[r.status] += 1
        return cls(
            total=len(results),
            passed=counts[TestStatus.PASS],
            failed=counts[TestStatus.FAIL],
            errored=counts[TestStatus.ERROR],
            timed_out=counts[TestStatus.TIMEOUT],
            skipped=counts[TestStatus.SKIPPED],
            total_runtime_s=sum(r.runtime_s for r in results),
        )

    @property
    def all_passed(self) -> bool:
        return self.total > 0 and self.passed == self.total
