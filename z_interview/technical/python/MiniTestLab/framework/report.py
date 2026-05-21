"""Report generation: JSON and CSV outputs.

Why separate JSON and CSV?
    - JSON keeps nested structure (metadata, suite summary) intact —
      good for dashboards, downstream tooling, and machine consumers.
    - CSV is flat but universally consumable (Excel, pandas, Jenkins
      plugins). Engineers love it for ad-hoc analysis.

Why a writer class instead of a function?
    Keeps the destination directory as state, allowing multiple
    writes (results, summary, per-test artifacts) without re-passing
    the path everywhere.
"""

from __future__ import annotations

import csv
import json
from contextlib import contextmanager
from dataclasses import asdict
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Iterator

from framework.logger import get_logger
from framework.models import TestResult, TestSuiteSummary

_logger = get_logger(__name__)


class ReportFormat(str, Enum):
    """Supported report formats."""

    JSON = "json"
    CSV = "csv"
    BOTH = "both"


@contextmanager
def _atomic_write(path: Path) -> Iterator[Path]:
    """Write to a temp file then rename, so readers never see partial data.

    Custom context manager example. Crashing mid-write would leave a
    truncated report; atomic rename avoids that and makes the reports
    safe to consume from another process.

    Interview talking point:
        "Atomic rename is the standard pattern for crash-safe file
         output on POSIX. Same trick CPython, sqlite, and most config
         managers use."
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    try:
        yield tmp
    except BaseException:
        if tmp.exists():
            tmp.unlink(missing_ok=True)
        raise
    else:
        tmp.replace(path)


class ReportWriter:
    """Generates JSON and/or CSV reports for a test run."""

    _CSV_HEADER: tuple[str, ...] = (
        "name", "status", "runtime_s", "timestamp", "error_message", "metadata",
    )

    def __init__(self, output_dir: Path) -> None:
        self._output_dir = output_dir
        self._output_dir.mkdir(parents=True, exist_ok=True)

    @property
    def output_dir(self) -> Path:
        return self._output_dir

    def write(
        self,
        results: list[TestResult],
        summary: TestSuiteSummary,
        *,
        fmt: ReportFormat = ReportFormat.JSON,
        run_id: str | None = None,
    ) -> list[Path]:
        """Write the report(s) and return the list of paths written."""
        run_id = run_id or self._default_run_id()
        written: list[Path] = []

        if fmt in {ReportFormat.JSON, ReportFormat.BOTH}:
            json_path = self._output_dir / f"report_{run_id}.json"
            self._write_json(json_path, results, summary, run_id)
            written.append(json_path)

        if fmt in {ReportFormat.CSV, ReportFormat.BOTH}:
            csv_path = self._output_dir / f"report_{run_id}.csv"
            self._write_csv(csv_path, results)
            written.append(csv_path)

        for path in written:
            _logger.info("Wrote report: %s", path)
        return written

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    @staticmethod
    def _default_run_id() -> str:
        # Compact, sortable, timezone-safe — perfect for filenames.
        return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    def _write_json(
        self,
        path: Path,
        results: list[TestResult],
        summary: TestSuiteSummary,
        run_id: str,
    ) -> None:
        payload = {
            "run_id": run_id,
            "summary": asdict(summary),
            "results": [r.to_dict() for r in results],
        }
        with _atomic_write(path) as tmp:
            with tmp.open("w", encoding="utf-8") as fh:
                json.dump(payload, fh, indent=2, default=str)
                fh.write("\n")

    def _write_csv(self, path: Path, results: list[TestResult]) -> None:
        with _atomic_write(path) as tmp:
            with tmp.open("w", encoding="utf-8", newline="") as fh:
                writer = csv.writer(fh)
                writer.writerow(self._CSV_HEADER)
                for r in results:
                    writer.writerow([
                        r.name,
                        r.status.value,
                        f"{r.runtime_s:.4f}",
                        r.timestamp,
                        r.error_message or "",
                        # metadata stays in one JSON-encoded cell so the
                        # CSV remains rectangular and Excel-friendly.
                        json.dumps(r.metadata, default=str, sort_keys=True),
                    ])
