#Q6: Check if nth bit is set
"""
Prompt:
Given a number and an index n, check if the nth bit is set.

10, 2 -> True (10 in binary is 1010)
"""

def is_bit_set(number: int, n: int) -> bool:
    return (number & (1 << n)) != 0