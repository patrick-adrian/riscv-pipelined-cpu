"""Unit tests for the report writer."""

from __future__ import annotations

import csv
import json
from pathlib import Path

import pytest

from framework.models import TestResult, TestStatus, TestSuiteSummary
from framework.report import ReportFormat, ReportWriter


def _make_results() -> list[TestResult]:
    return [
        TestResult(
            name="alpha",
            status=TestStatus.PASS,
            runtime_s=0.123,
            timestamp="2026-05-21T12:00:00+00:00",
            error_message=None,
            metadata={"k": 1},
        ),
        TestResult(
            name="beta",
            status=TestStatus.FAIL,
            runtime_s=0.456,
            timestamp="2026-05-21T12:00:01+00:00",
            error_message="bad",
            metadata={},
        ),
    ]


@pytest.fixture()
def results() -> list[TestResult]:
    return _make_results()


@pytest.fixture()
def summary(results: list[TestResult]) -> TestSuiteSummary:
    return TestSuiteSummary.from_results(results)


def test_writer_creates_directory(tmp_path: Path, results, summary) -> None:
    target = tmp_path / "nested" / "reports"
    writer = ReportWriter(output_dir=target)
    assert target.exists()
    paths = writer.write(results, summary, fmt=ReportFormat.JSON, run_id="t1")
    assert len(paths) == 1
    assert paths[0].name == "report_t1.json"


def test_json_report_shape(tmp_reports_dir: Path, results, summary) -> None:
    writer = ReportWriter(output_dir=tmp_reports_dir)
    paths = writer.write(results, summary, fmt=ReportFormat.JSON, run_id="abc")
    payload = json.loads(paths[0].read_text())

    assert payload["run_id"] == "abc"
    assert payload["summary"]["total"] == 2
    assert payload["summary"]["passed"] == 1
    assert payload["summary"]["failed"] == 1
    assert [r["name"] for r in payload["results"]] == ["alpha", "beta"]


def test_csv_report_columns(tmp_reports_dir: Path, results, summary) -> None:
    writer = ReportWriter(output_dir=tmp_reports_dir)
    paths = writer.write(results, summary, fmt=ReportFormat.CSV, run_id="abc")
    with paths[0].open() as fh:
        rows = list(csv.reader(fh))
    assert rows[0] == [
        "name", "status", "runtime_s", "timestamp", "error_message", "metadata",
    ]
    assert rows[1][0] == "alpha"
    assert rows[1][1] == "PASS"
    assert rows[2][1] == "FAIL"
    # metadata column must be valid JSON for downstream tooling.
    json.loads(rows[1][5])


def test_both_format_writes_two_files(tmp_reports_dir: Path, results, summary) -> None:
    writer = ReportWriter(output_dir=tmp_reports_dir)
    paths = writer.write(results, summary, fmt=ReportFormat.BOTH, run_id="dual")
    suffixes = sorted(p.suffix for p in paths)
    assert suffixes == [".csv", ".json"]


def test_summary_all_passed() -> None:
    only_pass = [
        TestResult(
            name="ok",
            status=TestStatus.PASS,
            runtime_s=0.01,
            timestamp="2026-01-01T00:00:00+00:00",
        )
    ]
    assert TestSuiteSummary.from_results(only_pass).all_passed is True


def test_summary_empty_is_not_passed() -> None:
    assert TestSuiteSummary.from_results([]).all_passed is False
