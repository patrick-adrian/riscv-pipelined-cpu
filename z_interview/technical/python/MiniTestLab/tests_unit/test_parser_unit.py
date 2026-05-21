"""Unit tests for the regex log parser."""

from __future__ import annotations

from pathlib import Path

import pytest

from framework.exceptions import LogParseError
from framework.parser import LogParser, LogSeverity


def test_parser_loads_sample(sample_log_path: Path) -> None:
    parser = LogParser(sample_log_path)
    events = list(parser.iter_events())
    assert len(events) >= 10
    # The "not-a-log-line-without-severity" line must be filtered out.
    assert all(e.severity in LogSeverity for e in events)


def test_severity_counts(sample_log_path: Path) -> None:
    counts = LogParser(sample_log_path).count_by_severity()
    assert counts[LogSeverity.INFO] > 0
    assert counts[LogSeverity.ERROR] >= 1
    assert counts[LogSeverity.CRITICAL] >= 1


def test_find_errors_returns_only_severe(sample_log_path: Path) -> None:
    errors = LogParser(sample_log_path).find_errors()
    assert errors, "expected at least one error/critical event"
    for e in errors:
        assert e.severity in {LogSeverity.ERROR, LogSeverity.CRITICAL}


def test_temperature_extraction(sample_log_path: Path) -> None:
    parser = LogParser(sample_log_path)
    temps = [e.metrics["temperature"] for e in parser.iter_events() if "temperature" in e.metrics]
    assert temps, "no temperature metrics extracted"
    assert max(temps) > 100.0, "expected at least one critical temperature reading"


def test_voltage_normalized_to_volts(sample_log_path: Path) -> None:
    parser = LogParser(sample_log_path)
    volts = [e.metrics["voltage"] for e in parser.iter_events() if "voltage" in e.metrics]
    assert volts, "no voltage metrics extracted"
    # The sample contains millivolt entries (e.g. VDD=1100mV). After
    # normalization no reading should look millivolt-shaped.
    assert all(0.5 < v < 2.0 for v in volts), volts


def test_missing_file_raises(tmp_path: Path) -> None:
    with pytest.raises(LogParseError):
        LogParser(tmp_path / "nope.log")


@pytest.mark.parametrize(
    "line,expected",
    [
        ("2026-01-01 00:00:00 [INFO] hello", LogSeverity.INFO),
        ("[warning] retry incoming", LogSeverity.WARNING),
        ("[ERROR] boom", LogSeverity.ERROR),
        ("[CRITICAL] dying", LogSeverity.CRITICAL),
        ("[fatal] truly dying", LogSeverity.CRITICAL),
    ],
)
def test_severity_normalization(tmp_path: Path, line: str, expected: LogSeverity) -> None:
    """Parametrized test — same logic, multiple inputs.

    Parametrization beats writing five near-identical tests; failures
    point to the *exact* input that broke.
    """
    log = tmp_path / "x.log"
    log.write_text(line + "\n")
    events = list(LogParser(log).iter_events())
    assert len(events) == 1
    assert events[0].severity is expected
