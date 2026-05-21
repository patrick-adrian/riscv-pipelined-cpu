"""Validation test package.

Importing this package triggers test registration via the
`@test_case` decorators in each submodule. The runner only sees a
test if its module has been imported at least once.

To add a new test:
    1. Drop a `test_*.py` file in this directory.
    2. Decorate one or more functions with `@test_case(...)`.
    3. Re-export the module from the explicit list below (or rely
       on `_auto_discover()` if you prefer dynamic discovery).
"""

from __future__ import annotations

import importlib
import pkgutil
from types import ModuleType


def _auto_discover() -> list[ModuleType]:
    """Import every `test_*.py` module in this package.

    Auto-discovery keeps the framework "drop a file and go" — the
    same UX pytest gives you. We could enumerate modules manually
    but every additional indirection is one more thing to forget.
    """
    discovered: list[ModuleType] = []
    for mod_info in pkgutil.iter_modules(__path__):
        if mod_info.name.startswith("test_"):
            discovered.append(importlib.import_module(f"{__name__}.{mod_info.name}"))
    return discovered


_AUTO_LOADED_MODULES: list[ModuleType] = _auto_discover()
