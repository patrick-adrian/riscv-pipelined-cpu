"""Test discovery and execution engine.

The runner glues everything together:
    - tests register themselves via the `@test_case` decorator
      (plugin-style registration — adding a new test never requires
      touching this file)
    - `TestRunner.run` executes selected tests, measures runtime,
      classifies exceptions, and aggregates results.

Why plugin-style registration?
    - Open/Closed principle: framework code stays closed for
      modification but open for extension.
    - Mirrors how pytest, Click commands, Flask routes work —
      familiar to anyone who has used Python at scale.

Why thread-based concurrency (not multiprocessing or asyncio)?
    - Validation tests are usually I/O-bound (subprocess, network,
      file I/O), where threads give real parallelism even with the
      GIL.
    - multiprocessing would force results to be picklable, which is
      annoying for ad-hoc test artifacts.
    - asyncio would force every test to be `async def`, defeating
      the goal of writing plain validation functions.
"""

from __future__ import annotations

import inspect
import threading
import time
import traceback
from concurrent.futures import Future, ThreadPoolExecutor, as_completed
from typing import Callable, Iterable, Optional

from framework.exceptions import (
    MiniTestLabError,
    TestExecutionError,
    TestTimeoutError,
)
from framework.logger import get_logger
from framework.models import TestCase, TestResult, TestStatus, TestSuiteSummary

_logger = get_logger(__name__)

# Module-level registry. The `@test_case` decorator populates this when
# test modules are imported. We protect it with a lock because tests
# can be registered from multiple threads in pathological cases.
_REGISTRY: dict[str, TestCase] = {}
_REGISTRY_LOCK = threading.Lock()


def test_case(
    *,
    name: Optional[str] = None,
    description: str = "",
    timeout_s: float = 10.0,
    tags: Iterable[str] = (),
) -> Callable[[Callable[..., None]], Callable[..., None]]:
    """Decorator that registers a function as a discoverable test.

    Example:
        @test_case(name="ping_localhost", timeout_s=5.0, tags=["net"])
        def ping_localhost() -> None:
            ...

    Decorator factory pattern: the outer call collects metadata,
    the returned `decorator` wraps the test function.
    """

    def decorator(func: Callable[..., None]) -> Callable[..., None]:
        if not callable(func):
            raise TypeError("@test_case must wrap a callable")
        # Allow the decorator's `name` arg to override the function name.
        test_name = name or func.__name__
        tc = TestCase(
            name=test_name,
            func=func,
            description=description or (inspect.getdoc(func) or "").strip(),
            timeout_s=timeout_s,
            tags=tuple(tags),
        )
        with _REGISTRY_LOCK:
            if test_name in _REGISTRY:
                raise ValueError(f"Duplicate test name: {test_name!r}")
            _REGISTRY[test_name] = tc
        return func

    return decorator


def get_registered_tests() -> dict[str, TestCase]:
    """Return a snapshot copy of the current test registry."""
    with _REGISTRY_LOCK:
        return dict(_REGISTRY)


def _clear_registry() -> None:
    """Test-only helper. Not part of the public API."""
    with _REGISTRY_LOCK:
        _REGISTRY.clear()


class TestRunner:
    """Executes a curated subset of registered tests."""

    def __init__(
        self,
        *,
        default_timeout_s: float = 10.0,
        max_workers: int = 1,
    ) -> None:
        if default_timeout_s <= 0:
            raise ValueError("default_timeout_s must be > 0")
        if max_workers < 1:
            raise ValueError("max_workers must be >= 1")
        self._default_timeout_s = default_timeout_s
        self._max_workers = max_workers

    # ------------------------------------------------------------------
    # Selection
    # ------------------------------------------------------------------

    def select(
        self,
        *,
        names: Optional[Iterable[str]] = None,
        tags: Optional[Iterable[str]] = None,
        run_all: bool = False,
    ) -> list[TestCase]:
        """Pick which registered tests to run.

        Selection rules:
            - `run_all=True`           -> every registered test.
            - `names` provided         -> filter by exact name match.
            - `tags` provided          -> filter by any matching tag.
            - All empty                -> raises (force the caller to be explicit).
        """
        registry = get_registered_tests()
        if run_all:
            return sorted(registry.values(), key=lambda tc: tc.name)

        selected: dict[str, TestCase] = {}
        if names:
            for n in names:
                if n not in registry:
                    raise MiniTestLabError(
                        f"Unknown test: {n!r}. Known tests: {sorted(registry)}"
                    )
                selected[n] = registry[n]
        if tags:
            tag_set = set(tags)
            for tc in registry.values():
                if tag_set.intersection(tc.tags):
                    selected[tc.name] = tc
        if not selected:
            raise MiniTestLabError("No tests selected. Pass names, tags, or run_all=True.")
        return sorted(selected.values(), key=lambda tc: tc.name)

    # ------------------------------------------------------------------
    # Execution
    # ------------------------------------------------------------------

    def run(self, cases: list[TestCase]) -> tuple[list[TestResult], TestSuiteSummary]:
        """Run the given cases and return (results, summary).

        Results are returned in the same order as `cases`, regardless
        of completion order under concurrency — which matters for
        deterministic report output.
        """
        if not cases:
            return [], TestSuiteSummary.from_results([])

        _logger.info(
            "Running %d test(s) with up to %d worker(s)",
            len(cases), self._max_workers,
        )
        results_by_name: dict[str, TestResult] = {}

        if self._max_workers == 1:
            for case in cases:
                results_by_name[case.name] = self._run_one(case)
        else:
            with ThreadPoolExecutor(max_workers=self._max_workers) as pool:
                futures: dict[Future[TestResult], TestCase] = {
                    pool.submit(self._run_one, c): c for c in cases
                }
                for fut in as_completed(futures):
                    case = futures[fut]
                    # Even if the worker died unexpectedly, we still
                    # produce a result — never let one bad test sink
                    # the whole report.
                    try:
                        results_by_name[case.name] = fut.result()
                    except Exception as exc:  # pragma: no cover - defensive
                        results_by_name[case.name] = TestResult(
                            name=case.name,
                            status=TestStatus.ERROR,
                            runtime_s=0.0,
                            timestamp=TestResult.utcnow_iso(),
                            error_message=f"Worker crashed: {exc}",
                        )

        ordered = [results_by_name[c.name] for c in cases]
        summary = TestSuiteSummary.from_results(ordered)
        self._log_summary(summary)
        return ordered, summary

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _run_one(self, case: TestCase) -> TestResult:
        """Execute a single test case with timing, timeout, and classification.

        We use a worker thread + `.join(timeout)` rather than `signal.alarm`
        because:
            - signals don't work cleanly on non-main threads.
            - signals are POSIX-only; this approach is cross-platform.

        Caveat (worth saying out loud in interviews):
            Python threads cannot be forcibly killed. If a test hangs
            inside a C extension, we log TIMEOUT and move on, but the
            thread keeps running in the background. For a production
            framework you'd add subprocess isolation here.
        """
        timeout_s = case.timeout_s or self._default_timeout_s
        _logger.info("> %s (timeout=%.1fs)", case.name, timeout_s)

        exc_holder: list[BaseException] = []
        meta_holder: dict[str, object] = {}

        def target() -> None:
            try:
                # If the test signature accepts `metadata`, give it a
                # mutable dict to publish per-test telemetry to.
                sig = inspect.signature(case.func)
                if "metadata" in sig.parameters:
                    case.func(metadata=meta_holder)
                else:
                    case.func()
            except BaseException as exc:  # noqa: BLE001 - captured and re-raised on main thread
                exc_holder.append(exc)

        start = time.perf_counter()
        worker = threading.Thread(target=target, name=f"test-{case.name}", daemon=True)
        worker.start()
        worker.join(timeout=timeout_s)
        elapsed = time.perf_counter() - start

        timestamp = TestResult.utcnow_iso()

        if worker.is_alive():
            _logger.error("TIMEOUT: %s after %.2fs", case.name, elapsed)
            return TestResult(
                name=case.name,
                status=TestStatus.TIMEOUT,
                runtime_s=elapsed,
                timestamp=timestamp,
                error_message=str(TestTimeoutError(case.name, timeout_s)),
                metadata=dict(meta_holder),
            )

        if exc_holder:
            exc = exc_holder[0]
            return self._classify_exception(case, exc, elapsed, timestamp, meta_holder)

        _logger.info("PASS:  %s in %.4fs", case.name, elapsed)
        return TestResult(
            name=case.name,
            status=TestStatus.PASS,
            runtime_s=elapsed,
            timestamp=timestamp,
            error_message=None,
            metadata=dict(meta_holder),
        )

    def _classify_exception(
        self,
        case: TestCase,
        exc: BaseException,
        elapsed: float,
        timestamp: str,
        meta: dict[str, object],
    ) -> TestResult:
        """Decide whether an exception means FAIL or ERROR.

        - AssertionError  -> FAIL  (the test ran but its check didn't hold)
        - TestTimeoutError -> TIMEOUT (defensive; usually caught upstream)
        - Anything else   -> ERROR (framework or environmental issue)
        """
        if isinstance(exc, AssertionError):
            status = TestStatus.FAIL
            msg = str(exc) or "assertion failed"
            _logger.warning("FAIL:  %s — %s", case.name, msg)
        elif isinstance(exc, TestTimeoutError):
            status = TestStatus.TIMEOUT
            msg = str(exc)
            _logger.error("TIMEOUT: %s — %s", case.name, msg)
        elif isinstance(exc, TestExecutionError):
            status = TestStatus.ERROR
            msg = str(exc)
            _logger.error("ERROR: %s — %s", case.name, msg)
        else:
            status = TestStatus.ERROR
            msg = f"{type(exc).__name__}: {exc}"
            _logger.error(
                "ERROR: %s — unexpected exception\n%s",
                case.name,
                "".join(traceback.format_exception(type(exc), exc, exc.__traceback__)),
            )

        return TestResult(
            name=case.name,
            status=status,
            runtime_s=elapsed,
            timestamp=timestamp,
            error_message=msg,
            metadata=dict(meta),
        )

    def _log_summary(self, summary: TestSuiteSummary) -> None:
        _logger.info(
            "Summary: total=%d pass=%d fail=%d error=%d timeout=%d skipped=%d (%.3fs)",
            summary.total, summary.passed, summary.failed,
            summary.errored, summary.timed_out, summary.skipped,
            summary.total_runtime_s,
        )
