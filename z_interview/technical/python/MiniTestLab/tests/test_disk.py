"""Filesystem and disk-space smoke tests."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path
from typing import Any

from framework.runner import test_case


@test_case(
    name="disk_free_above_threshold",
    description="Root filesystem must have >= 100 MB free.",
    timeout_s=2.0,
    tags=("disk", "smoke"),
)
def disk_free_above_threshold(metadata: dict[str, Any]) -> None:
    usage = shutil.disk_usage(Path("/").as_posix())
    metadata["total_bytes"] = usage.total
    metadata["used_bytes"] = usage.used
    metadata["free_bytes"] = usage.free
    metadata["free_mb"] = round(usage.free / (1024 * 1024), 2)

    assert usage.free >= 100 * 1024 * 1024, (
        f"Insufficient free space: {metadata['free_mb']} MB"
    )


@test_case(
    name="tempdir_write_read",
    description="Validate the OS temp dir is writable and round-trips data correctly.",
    timeout_s=3.0,
    tags=("disk", "io"),
)
def tempdir_write_read(metadata: dict[str, Any]) -> None:
    payload = b"MiniTestLab roundtrip\n" * 64

    # `tempfile.TemporaryDirectory` is a context manager: even if an
    # assertion fires, the directory and its contents are cleaned up.
    # This is exactly the kind of resource hygiene you want in CI —
    # the alternative is a slow accumulation of orphaned temp files.
    with tempfile.TemporaryDirectory(prefix="mtl_") as tmpdir:
        path = Path(tmpdir) / "roundtrip.bin"
        path.write_bytes(payload)
        read_back = path.read_bytes()

        metadata["tempdir"] = tmpdir
        metadata["bytes_written"] = len(payload)
        metadata["bytes_read"] = len(read_back)

        assert read_back == payload, "Temp file did not round-trip cleanly"
