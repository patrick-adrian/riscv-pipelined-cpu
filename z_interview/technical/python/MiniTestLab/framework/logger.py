"""Centralized logging configuration.

Why a dedicated logger module?
    - The stdlib `logging` module is hierarchical and global. Configuring
      it from many places leads to duplicated handlers, double-printed
      lines, and "why is debug not showing up?" headaches.
    - One module owns configuration. Everything else does
      `logger = get_logger(__name__)` and just *uses* it.

Why logging instead of print()?
    - Levels (DEBUG/INFO/WARNING/ERROR) instead of one firehose.
    - Structured output with timestamps, module names, and PIDs.
    - Routable: same code can log to console, file, syslog, Splunk...
    - Toggleable per-module without touching call sites.

Interview talking point:
    "print() is for scripts that humans run once. logging is for code
     that ships." Every production Python codebase you'll touch at
     AMD/Intel/Nvidia/Evertz/Qualcomm uses `logging` (or a wrapper
     like structlog) — never bare prints.
"""

from __future__ import annotations

import logging
import logging.handlers
import sys
from pathlib import Path
from typing import Optional

_DEFAULT_FORMAT = (
    "%(asctime)s | %(levelname)-8s | %(name)-22s | %(message)s"
)
_DEFAULT_DATEFMT = "%Y-%m-%d %H:%M:%S"

_ROOT_LOGGER_NAME = "minitestlab"
_CONFIGURED = False


class _ColorFormatter(logging.Formatter):
    """Colorize log levels on TTY output.

    Why ANSI codes inline?
        Avoids a hard dependency on `colorama`/`rich` for a tiny QoL
        feature. If stdout isn't a TTY (e.g. piped to a file or run
        in CI), the colors are stripped to keep logs grep-friendly.
    """

    _COLORS = {
        logging.DEBUG: "\033[37m",     # gray
        logging.INFO: "\033[36m",      # cyan
        logging.WARNING: "\033[33m",   # yellow
        logging.ERROR: "\033[31m",     # red
        logging.CRITICAL: "\033[1;31m",
    }
    _RESET = "\033[0m"

    def __init__(self, fmt: str, datefmt: str, use_color: bool) -> None:
        super().__init__(fmt=fmt, datefmt=datefmt)
        self._use_color = use_color

    def format(self, record: logging.LogRecord) -> str:
        msg = super().format(record)
        if not self._use_color:
            return msg
        color = self._COLORS.get(record.levelno, "")
        return f"{color}{msg}{self._RESET}" if color else msg


def configure_logging(
    *,
    log_dir: Optional[Path] = None,
    level: int = logging.INFO,
    verbose: bool = False,
    log_file_name: str = "minitestlab.log",
) -> logging.Logger:
    """Configure the framework's root logger exactly once.

    Args:
        log_dir: Directory for the rotating log file. If None, file
            logging is disabled (useful for unit tests).
        level: Base log level (overridden to DEBUG when verbose=True).
        verbose: Shortcut for "give me everything".
        log_file_name: Name of the log file inside `log_dir`.

    Returns:
        The configured `minitestlab` logger.

    Notes:
        Idempotent: calling this twice won't pile up handlers. This
        matters because pytest may import modules in surprising orders.
    """
    global _CONFIGURED

    effective_level = logging.DEBUG if verbose else level
    logger = logging.getLogger(_ROOT_LOGGER_NAME)
    logger.setLevel(effective_level)

    if _CONFIGURED:
        for h in logger.handlers:
            h.setLevel(effective_level)
        return logger

    logger.propagate = False
    logger.handlers.clear()

    console_handler = logging.StreamHandler(stream=sys.stdout)
    console_handler.setLevel(effective_level)
    console_handler.setFormatter(
        _ColorFormatter(
            fmt=_DEFAULT_FORMAT,
            datefmt=_DEFAULT_DATEFMT,
            use_color=sys.stdout.isatty(),
        )
    )
    logger.addHandler(console_handler)

    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        file_path = log_dir / log_file_name
        # Rotating handler prevents unbounded log growth in long CI runs.
        # 1 MB per file, keep 5 backups -> at most ~6 MB on disk.
        file_handler = logging.handlers.RotatingFileHandler(
            filename=file_path,
            maxBytes=1_000_000,
            backupCount=5,
            encoding="utf-8",
        )
        file_handler.setLevel(logging.DEBUG)  # file always gets everything
        file_handler.setFormatter(
            logging.Formatter(fmt=_DEFAULT_FORMAT, datefmt=_DEFAULT_DATEFMT)
        )
        logger.addHandler(file_handler)

    _CONFIGURED = True
    logger.debug("Logging configured (level=%s, file=%s)", effective_level, log_dir)
    return logger


def get_logger(name: str) -> logging.Logger:
    """Return a child logger under the framework's root.

    Using `getLogger("minitestlab.<module>")` keeps log namespaces
    tidy and lets users filter (e.g. `logging.getLogger("minitestlab.runner")`).
    """
    if name.startswith(_ROOT_LOGGER_NAME):
        return logging.getLogger(name)
    return logging.getLogger(f"{_ROOT_LOGGER_NAME}.{name}")
