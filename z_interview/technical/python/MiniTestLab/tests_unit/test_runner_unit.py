"""Unit tests for the test runner registration and execution."""

from __future__ import annotations

import time

import pytest

from framework.exceptions import MiniTestLabError
from framework.models import TestStatus
from framework.runner import (
    TestRunner,
    _clear_registry,
    get_registered_tests,
    test_case,
)


@pytest.fixture(autouse=True)
def isolated_registry():
    """Reset the global registry around each runner unit test.

    autouse=True means every test in this module gets the fixture
    even without declaring it — a clean way to enforce isolation
    when sharing global state with the framework.
    """
    _clear_registry()
    yield
    _clear_registry()


def test_decorator_registers_test() -> None:
    @test_case(name="t1", timeout_s=1.0, tags=("smoke",))
    def t1() -> None:
        pass

    registry = get_registered_tests()
    assert "t1" in registry
    assert registry["t1"].timeout_s == 1.0
    assert registry["t1"].tags == ("smoke",)


def test_duplicate_registration_raises() -> None:
    @test_case(name="dup")
    def a() -> None:
        pass

    with pytest.raises(ValueError, match="Duplicate test name"):
        @test_case(name="dup")
        def b() -> None:
            pass


def test_selection_requires_input() -> None:
    @test_case(name="x")
    def x() -> None:
        pass

    runner = TestRunner()
    with pytest.raises(MiniTestLabError):
        runner.select()


def test_selection_by_name_unknown() -> None:
    runner = TestRunner()
    with pytest.raises(MiniTestLabError, match="Unknown test"):
        runner.select(names=["does-not-exist"])


def test_runs_pass_and_fail() -> None:
    @test_case(name="passing", timeout_s=1.0)
    def passing() -> None:
        pass

    @test_case(name="failing", timeout_s=1.0)
    def failing() -> None:
        assert False, "intentional"

    runner = TestRunner()
    cases = runner.select(run_all=True)
    results, summary = runner.run(cases)

    by_name = {r.name: r for r in results}
    assert by_name["passing"].status is TestStatus.PASS
    assert by_name["failing"].status is TestStatus.FAIL
    assert "intentional" in (by_name["failing"].error_message or "")
    assert summary.total == 2
    assert summary.passed == 1
    assert summary.failed == 1


def test_runs_error_status_for_unexpected_exceptions() -> None:
    @test_case(name="boom", timeout_s=1.0)
    def boom() -> None:
        raise RuntimeError("kaboom")

    runner = TestRunner()
    results, summary = runner.run(runner.select(names=["boom"]))
    assert results[0].status is TestStatus.ERROR
    assert summary.errored == 1


def test_timeout_status() -> None:
    @test_case(name="slow", timeout_s=0.2)
    def slow() -> None:
        time.sleep(2.0)

    runner = TestRunner(default_timeout_s=1.0)
    results, _ = runner.run(runner.select(names=["slow"]))
    assert results[0].status is TestStatus.TIMEOUT


def test_metadata_propagates() -> None:
    @test_case(name="with_meta", timeout_s=1.0)
    def with_meta(metadata: dict[str, object]) -> None:
        metadata["sample"] = 42

    runner = TestRunner()
    results, _ = runner.run(runner.select(names=["with_meta"]))
    assert results[0].metadata == {"sample": 42}


def test_concurrent_execution() -> None:
    @test_case(name="a", timeout_s=2.0)
    def a() -> None:
        time.sleep(0.3)

    @test_case(name="b", timeout_s=2.0)
    def b() -> None:
        time.sleep(0.3)

    runner = TestRunner(max_workers=2)
    start = time.perf_counter()
    results, summary = runner.run(runner.select(run_all=True))
    elapsed = time.perf_counter() - start

    assert summary.passed == 2
    # If we ran serially this would take ~0.6s; with 2 workers it
    # should comfortably finish under 0.5s. Generous bound to keep
    # CI machines from flaking.
    assert elapsed < 0.55, f"Expected concurrent speedup, got {elapsed:.3f}s"
    # Order must match the input list regardless of completion order.
    assert [r.name for r in results] == ["a", "b"]
