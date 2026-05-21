"""MiniTestLab command-line entry point.

Why argparse?
    - Stdlib (zero dependencies — important for tools that ship into
      restricted CI environments where pip install isn't an option).
    - Auto-generated `--help`, `--version`, error messages.
    - Powerful enough for 95% of CLI tools (subcommands via
      `add_subparsers`, mutually exclusive groups, type coercion).

Why a thin main()?
    - Keeps all real logic in `framework/` modules, where it's
      testable. `main.py` is just glue. This is the same shape every
      mature Python CLI (pip, pytest, black, mypy) follows.

Exit code convention:
    0 -> all tests passed
    1 -> one or more tests failed/errored/timed out
    2 -> CLI usage error or config error

Following these conventions makes the tool friendly to CI systems
(Jenkins, GitHub Actions, GitLab CI) that interpret exit codes.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path
from typing import Optional

# Make sibling packages importable when this file is run as a script.
_REPO_ROOT = Path(__file__).resolve().parent
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from framework import (  # noqa: E402  (import after sys.path fix-up)
    ConfigError,
    MiniTestLabError,
    ReportFormat,
    ReportWriter,
    TestRunner,
    configure_logging,
    get_logger,
    get_registered_tests,
)
from framework.utils import env_flag, load_json_config  # noqa: E402

import tests  # noqa: E402,F401  -- triggers @test_case registration

_logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="minitestlab",
        description="MiniTestLab — a lightweight hardware/software validation test framework.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    selection = parser.add_argument_group("test selection")
    sel_group = selection.add_mutually_exclusive_group()
    sel_group.add_argument(
        "--test", "-t",
        action="append",
        default=None,
        metavar="NAME",
        help="Run a specific test by name (repeatable).",
    )
    sel_group.add_argument(
        "--tag",
        action="append",
        default=None,
        metavar="TAG",
        help="Run all tests carrying the given tag (repeatable).",
    )
    sel_group.add_argument(
        "--all", "-a",
        action="store_true",
        help="Run every registered test.",
    )
    sel_group.add_argument(
        "--list", "-l",
        action="store_true",
        help="List registered tests and exit.",
    )

    output = parser.add_argument_group("output")
    output.add_argument(
        "--report",
        choices=[fmt.value for fmt in ReportFormat],
        default=ReportFormat.JSON.value,
        help="Report format to emit.",
    )
    output.add_argument(
        "--reports-dir",
        type=Path,
        default=_REPO_ROOT / "reports",
        help="Where to write reports.",
    )
    output.add_argument(
        "--logs-dir",
        type=Path,
        default=_REPO_ROOT / "logs",
        help="Where to write rotating log files.",
    )
    output.add_argument(
        "--no-file-log",
        action="store_true",
        help="Disable file logging (console only).",
    )

    behavior = parser.add_argument_group("behavior")
    behavior.add_argument(
        "--config", "-c",
        type=Path,
        default=_REPO_ROOT / "configs" / "test_config.json",
        help="Optional JSON config file (defaults override CLI when present).",
    )
    behavior.add_argument(
        "--timeout",
        type=float,
        default=10.0,
        help="Default per-test timeout in seconds (tests may override).",
    )
    behavior.add_argument(
        "--workers", "-w",
        type=int,
        default=1,
        help="Max concurrent tests. Use >1 for I/O-bound suites.",
    )
    behavior.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable DEBUG logging.",
    )
    behavior.add_argument(
        "--version",
        action="version",
        version="MiniTestLab 0.1.0",
    )
    return parser


# ---------------------------------------------------------------------------
# Subcommand-like behaviors
# ---------------------------------------------------------------------------

def _list_tests() -> int:
    registry = get_registered_tests()
    if not registry:
        print("No tests registered.")
        return 0
    print(f"Registered tests ({len(registry)}):")
    for tc in sorted(registry.values(), key=lambda t: t.name):
        tags = ", ".join(tc.tags) if tc.tags else "-"
        desc = tc.description.splitlines()[0] if tc.description else ""
        print(f"  {tc.name:<32} timeout={tc.timeout_s:<5}s  tags=[{tags}]")
        if desc:
            print(f"    {desc}")
    return 0


def _resolve_selection(args: argparse.Namespace) -> dict[str, object]:
    """Translate CLI args into TestRunner.select() kwargs.

    Encapsulating this keeps `main()` readable and the translation
    logic unit-testable.
    """
    return {
        "names": args.test,
        "tags": args.tag,
        "run_all": args.all,
    }


def _apply_config_overrides(args: argparse.Namespace) -> None:
    """Optionally merge values from a JSON config file.

    Precedence: explicit CLI args > config file > argparse defaults.
    A config file is convenient for CI where dozens of flags would be
    unwieldy. We deliberately keep the schema tiny here.
    """
    if not args.config or not args.config.exists():
        return

    try:
        cfg = load_json_config(args.config)
    except ConfigError as exc:
        # Bad config is a usage error, not a test failure.
        raise SystemExit(f"error: {exc}") from exc

    # Only apply config values that the user did NOT explicitly override.
    # Detecting "explicit vs default" requires a sentinel approach; for
    # this small CLI we accept the simpler rule of "config can fill in
    # gaps for selection and timeout when CLI didn't specify them".
    defaults = vars(_build_parser().parse_args([]))
    current = vars(args)

    for key in ("timeout", "workers", "report"):
        if key in cfg and current.get(key) == defaults.get(key):
            current[key] = cfg[key]

    if cfg.get("tests") and not (args.test or args.tag or args.all):
        current["test"] = list(cfg["tests"])


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main(argv: Optional[list[str]] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    # Environment-variable opt-ins keep the CLI surface small.
    if env_flag("MINITESTLAB_DEBUG"):
        args.verbose = True

    _apply_config_overrides(args)

    configure_logging(
        log_dir=None if args.no_file_log else args.logs_dir,
        level=logging.INFO,
        verbose=args.verbose,
    )

    if args.list:
        return _list_tests()

    try:
        runner = TestRunner(
            default_timeout_s=args.timeout,
            max_workers=args.workers,
        )
        selection = runner.select(**_resolve_selection(args))  # type: ignore[arg-type]
        results, summary = runner.run(selection)
    except MiniTestLabError as exc:
        _logger.error("Framework error: %s", exc)
        return 2

    writer = ReportWriter(output_dir=args.reports_dir)
    writer.write(results, summary, fmt=ReportFormat(args.report))

    # Compact, human-friendly tail. We use print() here intentionally:
    # this is the final user-facing summary, not diagnostic logging.
    print()
    print("=" * 60)
    print(f"  RESULT: {'PASS' if summary.all_passed else 'FAIL'}")
    print(
        f"  total={summary.total} pass={summary.passed} "
        f"fail={summary.failed} error={summary.errored} "
        f"timeout={summary.timed_out}"
    )
    print(f"  runtime: {summary.total_runtime_s:.3f}s")
    print("=" * 60)

    return 0 if summary.all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
