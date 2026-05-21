"""Custom exception hierarchy for MiniTestLab.

Why custom exceptions?
    - They let callers distinguish "expected" framework failures from
      truly unexpected bugs.
    - They make `except` blocks specific, avoiding the classic
      anti-pattern of bare `except:` that silently swallows
      KeyboardInterrupt, SystemExit, and real bugs.
    - They carry structured context (test name, timeout value, etc.)
      instead of stuffing everything into a string.

Interview talking point:
    "Always derive a base exception per library (e.g.
     `requests.RequestException`). Users can `except MyLibError:` to
     trap anything from your library without catching everything."
"""

from __future__ import annotations

from typing import Optional


class MiniTestLabError(Exception):
    """Base class for all errors raised by the framework.

    Catching this base lets callers handle *any* framework-level
    failure without resorting to a bare `except Exception`.
    """


class ConfigError(MiniTestLabError):
    """Raised when configuration is missing, malformed, or invalid."""


class TestExecutionError(MiniTestLabError):
    """Raised when a test fails for a non-assertion reason.

    Examples:
        - A required tool (`ping`) is not installed.
        - A subprocess exits with an unexpected non-zero code that
          isn't itself the assertion being checked.
    """

    def __init__(self, test_name: str, message: str, *, cause: Optional[BaseException] = None) -> None:
        self.test_name = test_name
        self.cause = cause
        super().__init__(f"[{test_name}] {message}")


class TestTimeoutError(MiniTestLabError):
    """Raised when a test exceeds its allotted runtime.

    We don't reuse the built-in `TimeoutError` because we want to
    carry the test name and configured timeout for reporting.
    """

    def __init__(self, test_name: str, timeout_s: float) -> None:
        self.test_name = test_name
        self.timeout_s = timeout_s
        super().__init__(
            f"Test '{test_name}' exceeded timeout of {timeout_s:.2f}s"
        )


class LogParseError(MiniTestLabError):
    """Raised when a log file cannot be read or parsed."""
