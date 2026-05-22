"""
2. File + Data Processing
Q4: CSV parsing (super common)

Prompt:
Read a CSV of test results and return % pass rate.

test_id,status
1,PASS
2,FAIL
3,PASS
"""
import csv

def pass_rate(file):
    total = 0
    passed = 0

    with open(file) as f:
        reader = csv.DictReader(f)
        for row in reader:
            total += 1
            if row["status"] == "PASS":
                passed += 1

    return passed / total

def parse_csv(log_file: str) -> float:
    with open(log_file, "r") as f:
        lines = f.readlines()

    for line in lines:
        if "PASS" in line:
            pass_count += 1
    return pass_count / total_count

