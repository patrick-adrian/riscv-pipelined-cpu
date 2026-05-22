"""
Q5: Group test failures by module
test,module,status
t1,PHY,FAIL
t2,CPU,PASS
t3,PHY,FAIL

Output:

{"PHY": 2, "CPU": 0}
"""

def group_test_failures(log_file: str) -> dict[str, int]:
    with open(log_file, "r") as f:
        lines = f.readlines()

    for line in lines:
        if "FAIL" in line:
            module = line.split(",")[1].strip()
            failures[module] += 1
    return failures