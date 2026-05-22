""""
Q1: Parse error logs and count failures

Prompt:
You are given a log file. Count how many times each error type appears.

[INFO] System started
[ERROR] Timeout
[ERROR] Timeout
[WARN] Low voltage
[ERROR] CRC_FAIL
"""
from collections import defaultdict

def count_errors(lines):
    counts = defaultdict(int)

    for line in lines:
        if "[ERROR]" in line:
            error = line.split("[ERROR]")[1].strip()
            counts[error] += 1

    return counts

def count_errors(log_file: str) -> dict[str, int]:
    with open(log_file, "r") as f:
        lines = f.readlines()

    counts = defaultdict(int)

    for line in lines:
        if "[ERROR]" in line:
            error = line.split("[ERROR]")[1].strip()
            counts[error] += 1

    return counts
    