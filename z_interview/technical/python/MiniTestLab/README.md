# MiniTestLab

A lightweight, industry-style validation test framework written in modern Python.

MiniTestLab is meant to look like the kind of internal automation tool you'd find on a validation, firmware, or QA team at AMD, Intel, NVIDIA, Evertz, Qualcomm, etc. It's small enough to read in one sitting, but it demonstrates the patterns that show up in real production codebases:

- structured CLI with `argparse`
- centralized, rotating `logging`
- plugin-style test discovery via decorators
- safe `subprocess` usage
- regex log parsing with named groups and compiled patterns
- JSON / CSV reports written atomically
- a typed, dataclass-based domain model
- custom exception hierarchy
- pytest unit tests with fixtures and parametrization
- optional concurrent execution via `ThreadPoolExecutor`

---

## Table of contents

1. [Why this exists](#why-this-exists)
2. [Project layout](#project-layout)
3. [Quick start](#quick-start)
4. [Command-line usage](#command-line-usage)
5. [Adding a new test](#adding-a-new-test)
6. [Architecture](#architecture)
7. [Why each Python feature matters in industry](#why-each-python-feature-matters-in-industry)
8. [Interview talking points](#interview-talking-points)

---

## Why this exists

Most "build a test framework" tutorials produce a single 300-line script. Real validation tools instead split responsibilities across small, testable modules, exit with meaningful codes, write durable artifacts, and play nicely with CI.

This repo is a reference layout for those patterns. You can:

- read it to learn the conventions
- fork it as a starting point for a real tool
- use it to practice typing, decorators, context managers, and subprocess in a *realistic* context (not toy exercises)

---

## Project layout

```
MiniTestLab/
├── main.py                     # CLI entry point (argparse, exit codes)
├── pytest.ini                  # pytest config (limits collection to tests_unit/)
├── requirements.txt            # dev deps only — framework is stdlib-only
├── README.md
│
├── configs/
│   └── test_config.json        # Optional defaults consumed by main.py
│
├── logs/                       # Rotating log files written at runtime (gitignored)
├── reports/                    # JSON/CSV reports written at runtime (gitignored)
│
├── sample_logs/
│   └── device.log              # Canned input for the regex parser tests
│
├── framework/                  # The reusable bits (no test logic lives here)
│   ├── __init__.py             # Public API re-exports (facade)
│   ├── exceptions.py           # Custom exception hierarchy
│   ├── logger.py               # Centralized logging + rotating file handler
│   ├── models.py               # Dataclasses + TestStatus enum
│   ├── parser.py               # LogParser using compiled regex
│   ├── report.py               # JSON/CSV writer with atomic rename
│   ├── runner.py               # @test_case decorator + TestRunner
│   └── utils.py                # retry/timed decorators, run_command, config loader
│
├── tests/                      # Validation tests run by the framework
│   ├── __init__.py             # Auto-discovers test_*.py modules
│   ├── test_ping.py
│   ├── test_cpu.py
│   ├── test_disk.py
│   ├── test_parser.py
│   └── test_subprocess.py
│
└── tests_unit/                 # pytest unit tests for the framework itself
    ├── conftest.py             # Shared fixtures
    ├── test_parser_unit.py
    ├── test_report_unit.py
    ├── test_runner_unit.py
    └── test_utils_unit.py
```

Two important separations to internalize:

| Directory     | Purpose                                                 | Run with        |
| ------------- | ------------------------------------------------------- | --------------- |
| `tests/`      | "Validation" tests — what the framework *does*          | `python main.py`|
| `tests_unit/` | Unit tests for the framework code itself                | `pytest`        |

In an interview this is worth calling out explicitly: testing your test framework is a sanity check that catches embarrassing regressions.

---

## Quick start

```bash
cd MiniTestLab

# 1. Create an isolated environment. Always. Globally installed deps
#    are how you get the "works on my machine" problem.
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

# 2. Install dev dependencies (only pytest; the framework itself is stdlib-only).
pip install -r requirements.txt

# 3. Run the validation suite.
python main.py --all

# 4. Run framework unit tests.
pytest
```

---

## Command-line usage

```bash
# Pick specific tests by name (repeatable):
python main.py --test cpu_count_nonzero --test disk_free_above_threshold

# Filter by tag:
python main.py --tag smoke

# Run everything with verbose logging and a CSV report:
python main.py --all --verbose --report csv

# Just list what's registered, no execution:
python main.py --list

# Concurrent execution (useful for I/O-bound suites):
python main.py --all --workers 4

# Set a tighter default timeout:
python main.py --all --timeout 5

# Send reports somewhere else:
python main.py --all --reports-dir /tmp/mtl-reports --report both
```

Environment variables:

| Variable               | Effect                       |
| ---------------------- | ---------------------------- |
| `MINITESTLAB_DEBUG=1`  | Equivalent to `--verbose`    |

Exit codes (standard CI convention):

| Code | Meaning                                |
| ---- | -------------------------------------- |
| `0`  | All selected tests passed              |
| `1`  | One or more tests failed/errored/timed out |
| `2`  | Bad CLI usage or invalid config        |

---

## Adding a new test

Drop a new file in `tests/` named `test_*.py` and decorate any function:

```python
from framework.runner import test_case
from framework.utils import run_command

@test_case(
    name="memory_size_ge_8gb",
    description="Verify the box reports at least 8 GB of RAM.",
    timeout_s=2.0,
    tags=("memory", "smoke"),
)
def memory_size_ge_8gb(metadata: dict) -> None:
    # `metadata` is optional. Anything you put in it lands in the report.
    result = run_command(["free", "-b"], timeout_s=1.0)
    # ... parse result.stdout, assert on values, populate metadata ...
```

That's it — `tests/__init__.py` auto-discovers the module and the `@test_case` decorator registers the function globally. No central registration list to maintain.

---

## Architecture

```
                +-------------------+
                |     main.py       |   <- argparse, exit codes, thin glue
                +---------+---------+
                          |
                          v
                +-------------------+
                |   framework/      |
                |                   |
                |   runner.py  -----+---> registers @test_case'd functions
                |                   |     and executes them with timing,
                |                   |     timeout, classification.
                |                   |
                |   logger.py       |     ONE place that configures logging.
                |   models.py       |     Dataclasses + TestStatus enum.
                |   parser.py       |     Stream-friendly regex parser.
                |   report.py       |     Atomic JSON / CSV writer.
                |   utils.py        |     Decorators + subprocess helper.
                |   exceptions.py   |     Custom hierarchy under MiniTestLabError.
                +---------+---------+
                          ^
                          | imports
                          |
                +---------+---------+
                |     tests/        |   <- validation test cases
                +-------------------+
```

Notable design choices:

1. **Framework code never imports from `tests/`.** Tests depend on the framework; the framework knows nothing about specific tests. This keeps the framework reusable.
2. **Plugin-style registration.** Adding a test never requires editing the runner — just decorate a new function. Mirrors how pytest, Click commands, Flask routes work.
3. **Results returned in input order**, even under concurrency. Predictable report output matters when humans diff CI runs day to day.
4. **Atomic report writes.** We write to `report.json.tmp` and rename. A crash mid-write never produces a half-baked file.
5. **Stdlib only at runtime.** Validation tooling often ships into locked-down environments. Keeping zero runtime dependencies is a feature.

---

## Why each Python feature matters in industry

This is the section you actually want to skim before an interview.

| Feature            | Why it matters in real code |
| ------------------ | --------------------------- |
| `argparse`         | Stdlib, generates `--help` automatically, integrates with CI by way of exit codes. Reach for it before `click`/`typer` unless you really need their extras. |
| `pathlib.Path`     | Replaces `os.path.join` string surgery with an object. Cross-platform, methods (`.read_text()`, `.exists()`) compose better, integrates with `open()` since Python 3.6. |
| `typing`           | Catches bugs before runtime via mypy/pyright, doubles as documentation. In large codebases the difference between "Optional[str]" and "str" is the difference between a 3am page and a quiet weekend. |
| `dataclasses`      | Removes `__init__`/`__repr__`/`__eq__` boilerplate. `frozen=True` gives you hashable, immutable value objects for free. |
| `enum.Enum`        | Closes a vocabulary. `TestStatus.PASS` can't be misspelled the way `"pass"` can. |
| `logging`          | Levels, handlers, structured output, routing. Print statements don't have any of that. Every prod team uses logging. |
| `subprocess`       | Almost every automation script eventually shells out. Knowing to pass `list[str]`, never `shell=True` with untrusted input, and always set `timeout` is table stakes. |
| `re` (regex)       | Indispensable for log scraping. Compile once, name your groups, prefer character classes over `.*`. |
| `json` / `csv`     | The two formats every dashboard, ticketing system, and Excel-wielding manager understands. |
| `pytest`           | Fixture system, parametrization, assertion introspection. The de facto standard. |
| context managers   | Guarantee cleanup (file handles, locks, temp dirs) even on exceptions. `with` blocks > manual `try/finally`. |
| exception handling | A custom hierarchy lets callers `except MyLibError` precisely. Bare `except:` swallows `KeyboardInterrupt` and bugs. |
| generators         | Stream large inputs (logs, packet captures) without loading them into memory. `yield` is one of Python's quiet superpowers. |
| `__name__ == "__main__"` | Lets a file work both as a script and as an importable module. Standard for any module that has a main(). |

---

## Interview talking points

Things in this codebase worth pointing to in an interview:

1. **"How do you organize a Python project?"** — Walk through `framework/` vs `tests/` vs `tests_unit/`. Mention single-responsibility per module and the `__init__.py` re-export facade.
2. **"How would you handle test timeouts?"** — Point to `_run_one` in `runner.py`. Explain why `threading + .join(timeout)` is more portable than `signal.alarm`, and admit the limitation that Python threads can't be killed (production frameworks would isolate via subprocesses).
3. **"How do you avoid shell injection?"** — Point to `run_command` in `utils.py`. Always `list[str]`, never `shell=True` with user input, always a timeout, always check the binary exists first.
4. **"How do logs survive a crash mid-write?"** — Show `_atomic_write` in `report.py`. Standard temp-file-plus-rename trick.
5. **"How do you make a function flaky-tolerant without writing nested try/except?"** — Show the `retry` decorator with exponential backoff in `utils.py`. Stress: only retry transient failures, never non-idempotent operations.
6. **"Why an enum for status instead of strings?"** — Compare `TestStatus.PASS` (typed, autocompletable, catchable by mypy) vs `"pass"` (typo-prone).
7. **"How do you test the test framework?"** — Show `tests_unit/`, parametrized cases, fixture for registry isolation (`autouse=True` `_clear_registry`).
8. **"Why argparse instead of click/typer?"** — Stdlib means zero install friction in restricted CI/lab environments; click/typer are great when you need their richer UX but are a dependency to justify.

---

## Tradeoffs worth knowing

- **Thread-based concurrency** is fine for I/O-bound tests. CPU-bound suites would want `ProcessPoolExecutor`.
- **Auto-discovery** is convenient but can hide registration bugs. The runner does raise on duplicate names; a stricter framework might also validate signatures.
- **Stdlib-only runtime** is a deliberate constraint. If you need YAML configs, structured logging, or rich CLI tables, accept the dependency thoughtfully.
- **Result ordering by input** assumes test count is modest. For thousands of tests, you'd want streaming output and a database-backed report store.

---

## License

MIT — use it, fork it, ship it.
