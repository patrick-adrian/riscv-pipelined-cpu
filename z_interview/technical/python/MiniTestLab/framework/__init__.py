"""MiniTestLab framework package.

A lightweight, industry-style validation test framework.

Why expose a clean public API at the package level?
    In real codebases, importing implementation modules directly
    (`from framework.runner import TestRunner`) couples callers to
    internal layout. Re-exporting a curated surface here lets us
    reorganize internals without breaking downstream code.

Interview talking point:
    This pattern (the "facade" of a package) is common in tools like
    `requests`, `pytest`, and most production Python libraries.
"""

from framework.exceptions import (
    MiniTestLabError,
    TestTimeoutError,
    TestExecutionError,
    ConfigError,
    LogParseError,
)
from framework.models import TestStatus, TestResult, TestCase, TestSuiteSummary
from framework.runner import TestRunner, test_case, get_registered_tests
from framework.logger import get_logger, configure_logging
from framework.parser import LogParser, LogEvent, LogSeverity
from framework.report import ReportWriter, ReportFormat

__all__ = [
    "MiniTestLabError",
    "TestTimeoutError",
    "TestExecutionError",
    "ConfigError",
    "LogParseError",
    "TestStatus",
    "TestResult",
    "TestCase",
    "TestSuiteSummary",
    "TestRunner",
    "test_case",
    "get_registered_tests",
    "get_logger",
    "configure_logging",
    "LogParser",
    "LogEvent",
    "LogSeverity",
    "ReportWriter",
    "ReportFormat",
]

__version__ = "0.1.0"
