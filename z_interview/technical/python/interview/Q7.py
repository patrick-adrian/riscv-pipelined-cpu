"""
Q7: Toggle a bit in a number   
Prompt:
Given a number and an index n, toggle the nth bit.

10, 2 -> 14 (1010 -> 1110)
"""

def toggle_bit(number: int, n: int) -> int:
    return number ^ (1 << n)

