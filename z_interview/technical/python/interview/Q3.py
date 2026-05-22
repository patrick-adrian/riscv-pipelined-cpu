"""
Q3: Find first failure after boot

This is VERY realistic in firmware validation.

You need to:

find "BOOT COMPLETE"
return first ERROR after it
"""

def find_first_failure_after_boot(log_file: str) -> str:
    with open(log_file, "r") as f:
        lines = f.readlines()

    for line in lines[lines.index("BOOT COMPLETE") + 1:]:
        if "ERROR" in line:
            return line
    return "No error found after boot complete"