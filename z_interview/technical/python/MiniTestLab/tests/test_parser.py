"""Log-parser regression tests.

These exercise the framework's `LogParser` against the canned
`sample_logs/device.log` shipped with the repo. They double as a
real-world example of how to assert against parser output.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from framework.parser import LogParser, LogSeverity
from framework.runner import test_case

_REPO_ROOT = Path(__file__).resolve().parent.parent
_SAMPLE_LOG = _REPO_ROOT / "sample_logs" / "device.log"


@test_case(
    name="parser_finds_errors",
    description="Parser must detect ERROR/CRITICAL lines in the canned sample log.",
    timeout_s=4.0,
    tags=("parser", "logs"),
)
def parser_finds_errors(metadata: dict[str, Any]) -> None:
    assert _SAMPLE_LOG.exists(), f"Missing sample log: {_SAMPLE_LOG}"
    parser = LogParser(_SAMPLE_LOG)
    errors = parser.find_errors()
    metadata["error_count"] = len(errors)
    metadata["first_error"] = errors[0].message if errors else None
    assert len(errors) >= 1, "Expected at least one ERROR/CRITICAL line"


@test_case(
    name="parser_severity_counts",
    description="Severity histogram must contain INFO entries (basic sanity).",
    timeout_s=4.0,
    tags=("parser",),
)
def parser_severity_counts(metadata: dict[str, Any]) -> None:
    parser = LogParser(_SAMPLE_LOG)
    counts = parser.count_by_severity()
    metadata.update({sev.value: n for sev, n in counts.items()})
    assert counts[LogSeverity.INFO] > 0, "No INFO lines parsed; pattern may be broken"


@test_case(
    name="parser_extracts_metrics",
    description="At least one parsed line must yield a temperature or voltage metric.",
    timeout_s=4.0,
    tags=("parser",),
)
def parser_extracts_metrics(metadata: dict[str, Any]) -> None:
    parser = LogParser(_SAMPLE_LOG)
    with_metrics = [e for e in parser.iter_events() if e.metrics]
    metadata["events_with_metrics"] = len(with_metrics)
    assert with_metrics, "Parser failed to extract any temperature/voltage readings"
