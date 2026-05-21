#!/usr/bin/env python3
"""
binarySearch.py
---------------
Binary search is the second-most-common algorithm interview question
after "reverse a list". It looks simple, but most candidates get the
boundary conditions wrong on the first try.

WHY ASKED:
- Tests understanding of O(log n) divide-and-conquer.
- Probes loop invariants and off-by-one bugs (the classic killer).
- Many "advanced" interview questions reduce to binary search:
  - First/last occurrence of a value
  - Searching a rotated sorted array
  - "Smallest x such that f(x) is True" (binary search on the answer)

PRE-CONDITION: the input array MUST be sorted. State this clearly!
"""

from __future__ import annotations
import bisect                        # standard-library binary search
from typing import Sequence


# -------------------------------------------------------------------
# 1. Classic iterative binary search
# -------------------------------------------------------------------
def binary_search(arr: Sequence[int], target: int) -> int:
    """
    Return the index of `target` in sorted `arr`, or -1 if not found.

    Time:  O(log n)
    Space: O(1)

    INTERVIEW NOTE: THE THREE LANDMINES
    ------------------------------------
    1. Use `low + (high - low) // 2` instead of `(low + high) // 2`.
       In Python it doesn't matter (ints are unbounded), but in C/C++
       `low + high` can overflow! Calling this out shows hardware/
       low-level awareness -- VERY relevant for an AMD interview.

    2. Loop condition: `low <= high` (with `high = len(arr) - 1`) means
       we use an INCLUSIVE right boundary. Off-by-one bugs almost
       always come from mismatching the condition with the boundary.
       Pick one convention and stick with it.

    3. After comparing, advance by `mid + 1` or `mid - 1`, never `mid`.
       Otherwise an unequal `arr[mid]` can be re-examined and you
       infinite-loop.
    """
    low, high = 0, len(arr) - 1
    while low <= high:
        mid = low + (high - low) // 2   # overflow-safe midpoint
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            low = mid + 1               # target is in the right half
        else:
            high = mid - 1              # target is in the left half
    return -1                           # not found


# -------------------------------------------------------------------
# 2. Recursive binary search (elegant, but stack space)
# -------------------------------------------------------------------
def binary_search_recursive(
    arr: Sequence[int],
    target: int,
    low: int = 0,
    high: int | None = None,
) -> int:
    """
    Recursive form. Often clearer to write, but uses O(log n) stack
    space, and Python has NO tail-call optimization, so deep arrays
    risk RecursionError.

    INTERVIEW NOTE:
    - Default mutable args are a notorious Python footgun. Here we use
      `high: int | None = None` (an immutable sentinel) and resolve
      it inside the function -- safe pattern.
    """
    if high is None:
        high = len(arr) - 1
    if low > high:
        return -1
    mid = low + (high - low) // 2
    if arr[mid] == target:
        return mid
    if arr[mid] < target:
        return binary_search_recursive(arr, target, mid + 1, high)
    return binary_search_recursive(arr, target, low, mid - 1)


# -------------------------------------------------------------------
# 3. First / last occurrence  -- subtle variants of binary search
# -------------------------------------------------------------------
def first_occurrence(arr: Sequence[int], target: int) -> int:
    """
    Return the index of the FIRST occurrence of `target`, or -1.

    INTERVIEW NOTE:
    - When you find a match, DON'T return immediately. Record the
      index and keep searching LEFT (`high = mid - 1`) to find an
      earlier one.
    - This pattern -- "find a match, then keep narrowing" -- is the
      template for many leftmost/rightmost binary searches.
    """
    low, high = 0, len(arr) - 1
    result = -1
    while low <= high:
        mid = low + (high - low) // 2
        if arr[mid] == target:
            result = mid
            high = mid - 1              # keep looking left
        elif arr[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return result


def last_occurrence(arr: Sequence[int], target: int) -> int:
    """
    Mirror image of first_occurrence: on a match, keep looking RIGHT.
    """
    low, high = 0, len(arr) - 1
    result = -1
    while low <= high:
        mid = low + (high - low) // 2
        if arr[mid] == target:
            result = mid
            low = mid + 1               # keep looking right
        elif arr[mid] < target:
            low = mid + 1
        else:
            high = mid - 1
    return result


# -------------------------------------------------------------------
# 4. "Insertion point" -- the bisect module
# -------------------------------------------------------------------
def insertion_point_demo() -> None:
    """
    Python's standard library has `bisect`, which gives you binary
    search for free.

    INTERVIEW NOTE:
    - `bisect.bisect_left(arr, x)`  -> first index where `x` could go
                                       (returns the index of `x` if
                                       present at multiple places)
    - `bisect.bisect_right(arr, x)` -> just past any equal entries
    - `bisect.insort(arr, x)`       -> insert keeping sorted order

    These run in O(log n) for the search, but `insort` is O(n) overall
    because list insert is O(n) (it shifts elements). If you need fast
    insertions, use a sorted container library or a balanced tree.
    """
    arr = [1, 3, 5, 5, 5, 7, 9]
    print(f"bisect_left (5)  = {bisect.bisect_left(arr, 5)}")    # 2
    print(f"bisect_right(5)  = {bisect.bisect_right(arr, 5)}")   # 5
    print(f"bisect_left (4)  = {bisect.bisect_left(arr, 4)}")    # 2
    bisect.insort(arr, 4)
    print(f"after insort(4)  = {arr}")                            # [1,3,4,5,5,5,7,9]


# -------------------------------------------------------------------
# 5. "Binary search on the answer" -- a powerful pattern
# -------------------------------------------------------------------
def integer_sqrt(n: int) -> int:
    """
    Compute floor(sqrt(n)) using binary search.

    INTERVIEW NOTE: This is the "binary search on the answer" pattern.
    Instead of searching for a value in an array, we search for the
    largest integer `x` such that x*x <= n. The "array" is implicit:
    the range [0, n]. Any time the predicate is monotonic (False ...
    False True ... True), binary search works.

    Time: O(log n)  -- doubles of doubles converge fast.
    """
    if n < 0:
        raise ValueError("n must be non-negative")
    if n < 2:
        return n
    low, high = 1, n // 2 + 1
    result = 0
    while low <= high:
        mid = low + (high - low) // 2
        sq = mid * mid
        if sq == n:
            return mid
        if sq < n:
            result = mid                # mid is a valid candidate
            low = mid + 1
        else:
            high = mid - 1
    return result


# -------------------------------------------------------------------
# Demo
# -------------------------------------------------------------------
def _demo() -> None:
    arr = [1, 3, 5, 5, 5, 7, 9, 11, 13]
    print(f"array            = {arr}")
    print(f"search 7         = {binary_search(arr, 7)}")            # 5
    print(f"search 4         = {binary_search(arr, 4)}")            # -1
    print(f"recursive 11     = {binary_search_recursive(arr, 11)}") # 7
    print(f"first 5          = {first_occurrence(arr, 5)}")          # 2
    print(f"last  5          = {last_occurrence(arr, 5)}")           # 4
    print(f"isqrt(50)        = {integer_sqrt(50)}")                  # 7
    print(f"isqrt(144)       = {integer_sqrt(144)}")                 # 12
    print("---")
    insertion_point_demo()


if __name__ == "__main__":
    _demo()
