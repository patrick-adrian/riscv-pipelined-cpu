#!/usr/bin/env python3
# ^ Shebang line: tells Unix-like systems which interpreter to use
#   when you execute this file directly (e.g. `./sampleScript.py`).
#   `/usr/bin/env python3` finds python3 in the user's PATH, which is
#   more portable than hard-coding `/usr/bin/python3`.

"""
sampleScript.py
---------------
A "best practices" template script demonstrating clean, professional Python.

INTERVIEW TALKING POINTS:
- Module-level docstring (this triple-quoted string at top of file) is
  the canonical way to document a module. It is accessible at runtime
  via `__doc__`.
- The `if __name__ == "__main__":` guard separates "library code" from
  "script code" so the module can be imported without side effects.
- Type hints (PEP 484) document intent and enable static analysis with
  tools like mypy. They are NOT enforced at runtime.
- `argparse` is the standard-library tool for CLI parsing. Prefer it
  over manual `sys.argv` slicing for anything non-trivial.
"""

# -------------------------------------------------------------------
# Imports: PEP 8 ordering -> standard library, then third party, then
# local imports, separated by a blank line. Within each group, sort
# alphabetically for readability.
# -------------------------------------------------------------------
from __future__ import annotations  # Defers evaluation of type hints
                                    # (lets us write `list[int]` even
                                    # on older Python versions and avoid
                                    # forward-reference errors).

import argparse                     # Standard CLI argument parsing
import logging                      # Structured logging (preferred over print)
import sys                          # Exit codes, stderr, etc.
from pathlib import Path            # Modern OO-style file paths
from typing import Iterable         # Type hints for collections


# -------------------------------------------------------------------
# Module-level constants are UPPER_SNAKE_CASE (PEP 8).
# -------------------------------------------------------------------
DEFAULT_GREETING: str = "Hello"

# `logging.getLogger(__name__)` returns a logger named after the
# module. This is the idiomatic pattern: it allows the *application*
# (not the library) to configure handlers/levels.
log = logging.getLogger(__name__)


# -------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------
def greet(name: str, greeting: str = DEFAULT_GREETING) -> str:
    """
    Build a greeting string.

    Args:
        name:     The person to greet. Must be non-empty.
        greeting: Salutation prefix; defaults to "Hello".

    Returns:
        A formatted greeting, e.g. "Hello, Alice!".

    Raises:
        ValueError: If `name` is empty or whitespace-only.

    INTERVIEW NOTE:
    - Triple-quoted docstrings (PEP 257) document *what* a function
      does, *why*, parameters, returns, and exceptions.
    - f-strings (PEP 498) are the fastest and most readable way to
      format strings in modern Python (>=3.6).
    """
    # `str.strip()` returns a new string with leading/trailing whitespace
    # removed; using it lets us catch "   " as invalid input.
    if not name or not name.strip():
        # Fail loudly and early: raising lets callers handle it however
        # they want, rather than returning a sentinel like None.
        raise ValueError("name must be a non-empty string")

    return f"{greeting}, {name.strip()}!"


def greet_many(names: Iterable[str], greeting: str = DEFAULT_GREETING) -> list[str]:
    """
    Greet multiple people.

    INTERVIEW NOTE:
    - We type-hint the parameter as `Iterable[str]`, not `list[str]`.
      This is the "accept the least specific, return the most specific"
      principle: any iterable (list, tuple, generator, set) works.
    - We return a concrete `list[str]` so callers know exactly what
      they get back and can index/iterate freely.
    - List comprehensions are pythonic and usually faster than
      equivalent `for`-loops because the loop body runs in C.
    """
    return [greet(name, greeting) for name in names]


# -------------------------------------------------------------------
# CLI plumbing
# -------------------------------------------------------------------
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """
    Parse command-line arguments.

    INTERVIEW NOTE:
    - Accepting `argv` as a parameter (instead of reading sys.argv
      directly) makes this function *testable*: unit tests can pass
      in a fake argv. This is a small change with a big payoff.
    """
    parser = argparse.ArgumentParser(
        description="Greet one or more people from the command line.",
    )
    parser.add_argument(
        "names",
        nargs="+",                  # one or more positional arguments
        help="Name(s) of the person/people to greet.",
    )
    parser.add_argument(
        "-g", "--greeting",
        default=DEFAULT_GREETING,
        help=f"Greeting prefix (default: {DEFAULT_GREETING!r}).",
        # !r in an f-string calls repr() -> shows quotes around the string
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,                  # argparse will auto-convert to Path
        help="Optional file to write greetings to.",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",        # boolean flag, no value needed
        help="Enable debug logging.",
    )
    return parser.parse_args(argv)


def configure_logging(verbose: bool) -> None:
    """
    Configure root logger format and level.

    INTERVIEW NOTE:
    - Loggers are hierarchical and configured once at app startup.
    - The format string includes module name and level so logs are
      self-describing when grepping through large outputs (very common
      in HW/EDA flows).
    """
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        # Send logs to stderr so stdout can be cleanly piped/redirected.
        stream=sys.stderr,
    )


def main(argv: list[str] | None = None) -> int:
    """
    Entry point. Returns a Unix-style exit code (0 = success).

    INTERVIEW NOTE:
    - Returning an int from main() and passing it to sys.exit()
      gives proper exit codes to the shell. This matters in CI
      pipelines and Makefiles.
    - We wrap the body in try/except so the script always exits
      cleanly with a useful message instead of dumping a traceback
      on the user.
    """
    args = parse_args(argv)
    configure_logging(args.verbose)

    log.debug("Parsed arguments: %s", args)

    try:
        greetings = greet_many(args.names, greeting=args.greeting)
    except ValueError as e:
        # Log error to stderr and signal failure to the shell.
        log.error("Bad input: %s", e)
        return 1

    if args.output:
        # `Path.write_text` is a one-liner replacement for the older
        # open()/write()/close() dance. Uses context managers internally.
        args.output.write_text("\n".join(greetings) + "\n", encoding="utf-8")
        log.info("Wrote %d greeting(s) to %s", len(greetings), args.output)
    else:
        for line in greetings:
            print(line)

    return 0


# -------------------------------------------------------------------
# The __name__ guard.
#
# When Python runs a file directly, it sets __name__ == "__main__".
# When the file is *imported*, __name__ is set to the module's name
# instead. This guard ensures `main()` only runs when executed as a
# script, NOT when something does `import sampleScript`.
#
# This is the single most important Python idiom to know for an
# interview.
# -------------------------------------------------------------------
if __name__ == "__main__":
    sys.exit(main())
