"""
Q2: Extract timestamps of failures

Prompt:
Given:

2026-01-01 10:00:01 INFO Boot
2026-01-01 10:00:03 ERROR FAIL_INIT

Return timestamps of errors.
"""

def extract_timestamps(log_file: str) -> list[str]:
    with open(log_file, "r") as f:
        lines = f.readlines()

    timestamps = []
    for line in lines:
        if "[ERROR]" in line:
            timestamp = line.split("[ERROR]")[0].strip()
            timestamps.append(timestamp)
    return timestamps