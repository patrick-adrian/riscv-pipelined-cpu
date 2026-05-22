"""
#Q8: Count number of 1s (bit population)
"""

def count_ones(x):
    count = 0
    while x:
        x &= x - 1
        count += 1
    return count