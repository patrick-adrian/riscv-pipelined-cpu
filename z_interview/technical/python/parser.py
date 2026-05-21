#!/usr/bin/env python3
"""
parser.py
---------
A general-purpose log parser. For a hardware/systems-design role,
parsing simulator/EDA logs is BREAD AND BUTTER: post-processing
waveforms, scraping error counts, computing statistics from
gigabyte-scale dumps.

This script demonstrates:
  - Regular expressions with `re.compile` for performance + readability
  - Dataclasses (PEP 557) for clean record-like types
  - Generators (`yield`) for memory-efficient streaming of huge files
  - Context managers (`with open(...)`) for guaranteed file closing
  - Enum for fixed sets of log levels
  - Clean CLI via argparse
  - "Library + script" structure: importable AND runnable

EXAMPLE LOG LINE this parser understands:
    2026-05-21T16:13:42.123 [INFO]  fetch_stage: PC=0x80000004 issued

You can swap the regex to match any real log format. The key idea is
that parsing logs cleanly is a SOLVED PROBLEM if you reach for the
right Python tools.
"""

from __future__ import annotations

import argparse
import re                          # `re` is the standard regex module
import sys
from collections import Counter   # specialized dict for counting
from dataclasses import dataclass # decorator that auto-generates __init__, __repr__, etc.
from datetime import datetime
from enum import Enum             # type-safe enumeration
from pathlib import Path
from typing import Iterator, TextIO


# -------------------------------------------------------------------
# Enum for log levels.
#
# INTERVIEW NOTE:
# - Using an Enum gives type-safe, IDE-autocompletable constants.
# - Compare `level is LogLevel.ERROR` (clean) to magic strings like
#   `level == "ERROR"` (typo-prone).
# - `auto()` assigns each member a unique integer automatically.
# -------------------------------------------------------------------
class LogLevel(str, Enum):
    """
    Inheriting from `str` makes each member behave like a string
    (so it serializes nicely to JSON, prints as "INFO", etc.) while
    still being a proper Enum.
    """
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARN = "WARN"
    ERROR = "ERROR"
    FATAL = "FATAL"

    @classmethod
    def from_str(cls, s: str) -> "LogLevel":
        """Normalize string -> enum, default to INFO if unknown."""
        # `cls._value2member_map_` is the internal lookup table. We use
        # the public `cls(s)` constructor inside a try/except instead.
        try:
            return cls(s.upper())
        except ValueError:
            return cls.INFO


# -------------------------------------------------------------------
# Dataclass: a clean, type-hinted record type.
#
# INTERVIEW NOTE:
# - `@dataclass` (PEP 557) auto-generates __init__, __repr__, __eq__.
# - `frozen=True` makes instances immutable (like a namedtuple but
#   with type hints and defaults). Immutable records are easier to
#   reason about and safe to hash.
# - `slots=True` (Py3.10+) removes the per-instance __dict__, saving
#   memory when you parse millions of log lines.
# -------------------------------------------------------------------
@dataclass(frozen=True, slots=True)
class LogEntry:
    timestamp: datetime
    level: LogLevel
    component: str       # e.g. "fetch_stage"
    message: str         # the human-readable body


# -------------------------------------------------------------------
# Compile the regex ONCE at module load time.
#
# INTERVIEW NOTE:
# - `re.compile` precompiles the pattern. Inside a loop over a million
#   lines, this is dramatically faster than calling `re.match` with
#   the pattern string each time (which would recompile).
# - Named groups `(?P<name>...)` make the resulting match object
#   self-documenting: `m.group("level")` beats `m.group(2)`.
# - The `re.VERBOSE` flag lets us spread the pattern across multiple
#   lines with comments -- huge readability win for non-trivial regex.
# -------------------------------------------------------------------
LOG_LINE_RE: re.Pattern[str] = re.compile(
    r"""
    ^                                  # start of line
    (?P<ts>\d{4}-\d{2}-\d{2}T          # date: YYYY-MM-DD T
           \d{2}:\d{2}:\d{2}           # time: HH:MM:SS
           (?:\.\d+)?)                 # optional fractional seconds
    \s+\[(?P<level>[A-Z]+)\]           # log level in brackets
    \s+(?P<component>\w+):             # component name + colon
    \s+(?P<msg>.*)$                    # rest of the line
    """,
    re.VERBOSE,
)


# -------------------------------------------------------------------
# Parsing: generator over a file handle.
#
# INTERVIEW NOTE:
# - `yield` makes this a *generator function*. Instead of building a
#   list of millions of LogEntry objects in memory, we hand them out
#   one at a time as the caller consumes them.
# - The caller can wrap us with `list(parse_log(...))` if they DO
#   want everything in memory -- their choice.
# - Iterating directly over the file (`for line in f`) reads
#   line-by-line lazily, which is the canonical pattern for
#   big-file processing.
# -------------------------------------------------------------------
def parse_log(stream: TextIO) -> Iterator[LogEntry]:
    """
    Yield one `LogEntry` per matching line from `stream`.

    Lines that don't match the pattern are silently skipped, but a
    real production parser would log/count them -- see `parse_file`.
    """
    for raw in stream:
        # `str.rstrip("\n")` is cheaper than `.strip()` if you only
        # care about the trailing newline (and want to keep indentation
        # inside the message).
        line = raw.rstrip("\n")
        match = LOG_LINE_RE.match(line)
        if not match:
            continue

        # `match.groupdict()` returns {name: captured_text} for all
        # named groups -- very ergonomic.
        gd = match.groupdict()

        # Handle the two timestamp variants (with/without fractional secs).
        ts_str = gd["ts"]
        fmt = "%Y-%m-%dT%H:%M:%S.%f" if "." in ts_str else "%Y-%m-%dT%H:%M:%S"
        try:
            ts = datetime.strptime(ts_str, fmt)
        except ValueError:
            # If a timestamp is malformed, skip the line rather than
            # crashing the entire parse. Defensive parsing matters when
            # logs come from third-party tools.
            continue

        yield LogEntry(
            timestamp=ts,
            level=LogLevel.from_str(gd["level"]),
            component=gd["component"],
            message=gd["msg"],
        )


def parse_file(path: Path) -> Iterator[LogEntry]:
    """
    Open `path` and yield LogEntry objects. The context manager
    guarantees the file handle is closed even if an exception is
    raised inside the loop.

    INTERVIEW NOTE:
    - The `with` statement is the pythonic way to manage resources
      (files, locks, network connections). It calls __enter__ /
      __exit__ on the context manager, which guarantees cleanup.
    - Using `yield from` would *not* work here, because the file
      would close before the caller finished iterating. We must
      stay inside the `with` block during iteration -- hence
      `yield` inside the loop.
    """
    with path.open("r", encoding="utf-8", errors="replace") as f:
        for entry in parse_log(f):
            yield entry


# -------------------------------------------------------------------
# Aggregation helpers
# -------------------------------------------------------------------
def summarize(entries: Iterator[LogEntry]) -> dict[str, object]:
    """
    Walk an iterator of LogEntry and compute summary statistics.

    INTERVIEW NOTE:
    - `collections.Counter` is a dict subclass purpose-built for
      counting. `c[key] += 1` works even on the first hit (defaults
      to 0). `.most_common(n)` returns the top-n by count.
    - We deliberately accept an `Iterator` (not a list) so this
      composes cleanly with the streaming parser -- no materialization
      required.
    """
    level_counts: Counter[LogLevel] = Counter()
    component_counts: Counter[str] = Counter()
    total = 0
    first: datetime | None = None
    last: datetime | None = None

    for entry in entries:
        total += 1
        level_counts[entry.level] += 1
        component_counts[entry.component] += 1
        # Track time span -- on the first pass, both are None.
        if first is None or entry.timestamp < first:
            first = entry.timestamp
        if last is None or entry.timestamp > last:
            last = entry.timestamp

    return {
        "total_lines": total,
        "by_level": dict(level_counts),
        "top_components": component_counts.most_common(5),
        "first_timestamp": first,
        "last_timestamp": last,
    }


# -------------------------------------------------------------------
# CLI
# -------------------------------------------------------------------
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Parse and summarize a structured log file.",
    )
    parser.add_argument("log_file", type=Path, help="Path to the log file.")
    parser.add_argument(
        "--level",
        type=LogLevel.from_str,
        help="Only print entries at or above this level.",
    )
    parser.add_argument(
        "--component",
        help="Only print entries from this component.",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print summary statistics instead of individual lines.",
    )
    return parser.parse_args(argv)


# Ordered by severity so we can do `level.severity >= threshold.severity`.
_SEVERITY = {lvl: i for i, lvl in enumerate(LogLevel)}


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    if not args.log_file.exists():
        print(f"error: file not found: {args.log_file}", file=sys.stderr)
        return 1

    entries = parse_file(args.log_file)

    # ---- optional filters ----
    if args.level is not None:
        threshold = _SEVERITY[args.level]
        entries = (e for e in entries if _SEVERITY[e.level] >= threshold)
    if args.component is not None:
        entries = (e for e in entries if e.component == args.component)
    # NOTE: each filter above is itself a generator -- so the whole
    # pipeline stays lazy. Nothing is materialized until we iterate.

    if args.summary:
        stats = summarize(entries)
        for k, v in stats.items():
            print(f"{k:>18}: {v}")
    else:
        for e in entries:
            print(f"{e.timestamp.isoformat()} {e.level.value:5} "
                  f"{e.component}: {e.message}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
