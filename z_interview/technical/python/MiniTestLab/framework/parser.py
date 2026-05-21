"""Regex-based log parser for device/firmware/system logs.

Why a dedicated parser module?
    - Regex grows fast. Centralizing patterns lets reviewers spot
      duplication and edge cases.
    - Compiling patterns once (at import time) is cheaper than
      re-compiling inside a hot loop.
    - It's the natural place for the "extract structured events
      from semi-structured text" responsibility.

Why not pull in a heavy parser library?
    For line-oriented logs (which is 99% of validation output)
    regex is the right tool. We'd reach for `pyparsing` or a real
    grammar only for nested formats.

Interview talking point:
    "Regex is great for tokenizing line-oriented data; it's the wrong
     tool for matching balanced structures (HTML, JSON, nested code).
     Know when to switch to a real parser."
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Iterator, Optional

from framework.exceptions import LogParseError
from framework.logger import get_logger

_logger = get_logger(__name__)


class LogSeverity(str, Enum):
    """Severity vocabulary normalized across heterogeneous logs."""

    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


# --- Compiled regex patterns ------------------------------------------------
#
# We use named groups (`(?P<name>...)`) so callers can extract fields by
# meaningful keys rather than positional indices. Positional groups in
# anything beyond a one-liner is a recipe for off-by-one bugs.
#
# Each pattern is anchored conservatively. We avoid `.*` greedy matches
# spanning the whole line where a `[^\s]+` token would do; that keeps
# performance predictable on big log files.

_SEVERITY_RE = re.compile(
    r"""
    \[                                                  # opening bracket
    (?P<severity>DEBUG|INFO|WARN(?:ING)?|ERROR|CRIT(?:ICAL)?|FATAL)
    \]                                                  # closing bracket
    """,
    re.VERBOSE | re.IGNORECASE,
)

_TIMESTAMP_RE = re.compile(
    r"(?P<ts>\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d+)?)"
)

_TEMP_RE = re.compile(
    r"""
    (?:temp(?:erature)?|tjunction|tcase)\s*[:=]\s*
    (?P<value>-?\d+(?:\.\d+)?)\s*
    (?P<unit>°?\s*[CFK])
    """,
    re.VERBOSE | re.IGNORECASE,
)

_VOLT_RE = re.compile(
    r"""
    (?:vcc|vdd|voltage|v_in|v_out)\s*[:=]\s*
    (?P<value>-?\d+(?:\.\d+)?)\s*
    (?P<unit>m?V)\b
    """,
    re.VERBOSE | re.IGNORECASE,
)


_NORMALIZE_SEVERITY: dict[str, LogSeverity] = {
    "DEBUG": LogSeverity.DEBUG,
    "INFO": LogSeverity.INFO,
    "WARN": LogSeverity.WARNING,
    "WARNING": LogSeverity.WARNING,
    "ERROR": LogSeverity.ERROR,
    "CRIT": LogSeverity.CRITICAL,
    "CRITICAL": LogSeverity.CRITICAL,
    "FATAL": LogSeverity.CRITICAL,
}


@dataclass(frozen=True)
class LogEvent:
    """A single structured event extracted from a log line."""

    line_no: int
    severity: LogSeverity
    timestamp: Optional[str]
    message: str
    metrics: dict[str, float] = field(default_factory=dict)


class LogParser:
    """Stream-friendly parser for line-oriented device logs.

    Designed to handle large files via a generator interface — we
    never load the whole log into memory.
    """

    def __init__(self, path: Path) -> None:
        if not path.exists():
            raise LogParseError(f"Log file not found: {path}")
        if not path.is_file():
            raise LogParseError(f"Not a regular file: {path}")
        self._path = path

    @property
    def path(self) -> Path:
        return self._path

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def iter_events(self) -> Iterator[LogEvent]:
        """Yield `LogEvent`s one at a time from the underlying file.

        Generators shine here: a 2 GB log file would crush a naive
        `readlines()` approach, but with `yield` we hold one line at
        a time in memory.
        """
        try:
            # `with` ensures the file handle is closed even on exception.
            with self._path.open("r", encoding="utf-8", errors="replace") as fh:
                for line_no, raw_line in enumerate(fh, start=1):
                    event = self._parse_line(line_no, raw_line.rstrip("\n"))
                    if event is not None:
                        yield event
        except OSError as exc:
            raise LogParseError(f"Failed to read {self._path}: {exc}") from exc

    def count_by_severity(self) -> dict[LogSeverity, int]:
        """Tally events by severity. Useful for quick health checks."""
        counts = {sev: 0 for sev in LogSeverity}
        for event in self.iter_events():
            counts[event.severity] += 1
        return counts

    def find_errors(self) -> list[LogEvent]:
        """Return only ERROR/CRITICAL events."""
        return [
            e for e in self.iter_events()
            if e.severity in {LogSeverity.ERROR, LogSeverity.CRITICAL}
        ]

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _parse_line(self, line_no: int, line: str) -> Optional[LogEvent]:
        """Convert a raw line into a `LogEvent`, or None if not interesting."""
        sev_match = _SEVERITY_RE.search(line)
        if sev_match is None:
            return None
        severity = _NORMALIZE_SEVERITY[sev_match.group("severity").upper()]

        ts_match = _TIMESTAMP_RE.search(line)
        timestamp = ts_match.group("ts") if ts_match else None

        metrics: dict[str, float] = {}
        temp_match = _TEMP_RE.search(line)
        if temp_match:
            metrics["temperature"] = float(temp_match.group("value"))
        volt_match = _VOLT_RE.search(line)
        if volt_match:
            value = float(volt_match.group("value"))
            unit = volt_match.group("unit").lower()
            # Normalize to volts so downstream code doesn't have to.
            metrics["voltage"] = value / 1000.0 if unit == "mv" else value

        return LogEvent(
            line_no=line_no,
            severity=severity,
            timestamp=timestamp,
            message=line.strip(),
            metrics=metrics,
        )
