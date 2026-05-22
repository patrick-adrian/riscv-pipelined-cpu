#!/usr/bin/env python3
"""
sortList.py
-----------
Sorting is THE most common algorithm question. Interviewers expect you
to know:

  - The two built-in interfaces and how they differ.
  - How to sort by a custom key (lambdas, operator.itemgetter, etc.).
  - At least ONE comparison-based sort you can write from memory
    (merge sort and quicksort are the classics).
  - Time and space complexity, and what "stable" means.

Python's built-in sort is **Timsort** (a hybrid of merge sort and
insertion sort). It is O(n log n) worst-case, stable, and runs in C --
so in production code you should almost never write your own sort.
But you must be able to *explain* how one works.
"""

from __future__ import annotations
from operator import itemgetter
from typing import Callable, TypeVar

T = TypeVar("T")


# -------------------------------------------------------------------
# 1. sorted() vs list.sort() -- the built-in interfaces
# -------------------------------------------------------------------
def builtin_examples() -> None:
    """
    Demonstrate Python's two sorting interfaces.

    INTERVIEW NOTE:
    - `sorted(iterable)` returns a NEW list. Works on any iterable
      (set, tuple, generator). Original is untouched.
    - `list.sort()` sorts IN PLACE and returns None. Only works on
      lists.
    - Both accept `key=` (a callable applied to each element to
      derive the sort key) and `reverse=True`.
    - Both are STABLE: equal elements keep their relative order.
      Stability matters when sorting by multiple keys.
    """
    data = [3, 1, 4, 1, 5, 9, 2, 6]

    new_list = sorted(data)            # data is unchanged
    print(f"sorted()     -> {new_list},   original still {data}")

    data.sort()                        # mutates in place
    print(f"list.sort()  -> {data}")

    # ---- custom key ----
    words = ["banana", "fig", "apple", "cherry"]
    # `key=len` sorts by the *length* of each word, not the word itself.
    by_length = sorted(words, key=len)
    print(f"by length    -> {by_length}")

    # lambda for arbitrary keys -- here, sort by last letter:
    by_last = sorted(words, key=lambda w: w[-1])
    print(f"by last char -> {by_last}")

    # ---- multi-key sort using tuples ----
    # Tuples compare lexicographically: first element first, then second.
    # This gives us "primary/secondary key" sorting for free.
    people = [("Alice", 30), ("Bob", 25), ("Alice", 25), ("Bob", 30)]
    # Sort by name ASC, then age DESC. Trick: negate the int to flip order
    # for a single field while leaving the rest ascending.
    multi = sorted(people, key=lambda p: (p[0], -p[1]))
    print(f"multi-key    -> {multi}")

    # `operator.itemgetter` is the fast, C-implemented equivalent of
    # `lambda x: x[i]`. Prefer it for performance and readability.
    by_age = sorted(people, key=itemgetter(1))
    print(f"itemgetter   -> {by_age}")


# -------------------------------------------------------------------
# 2. Bubble Sort -- O(n^2). Educational only.
# -------------------------------------------------------------------
def bubble_sort(items: list[T]) -> list[T]:
    """
    Repeatedly walk the list, swapping adjacent out-of-order pairs.
    After each pass, the largest unsorted element "bubbles" to the end.

    Time:  O(n^2) worst & average, O(n) best (already sorted, with the
                                              early-exit flag below).
    Space: O(1) -- in place.
    Stable: yes.

    INTERVIEW NOTE:
    - The `swapped` flag is the standard optimization: if a full pass
      makes zero swaps, the list is sorted and we exit early.
    - We work on a *copy* so the caller's list isn't mutated. That's
      a design choice -- some implementations sort in place. Be
      explicit about which one yours does.
    """
    arr = list(items)                  # shallow copy so caller is safe
    n = len(arr)
    for i in range(n):
        swapped = False
        # After i passes, the last i elements are already in place.
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break
    return arr


# -------------------------------------------------------------------
# 3. Insertion Sort -- O(n^2), but fast on small / nearly-sorted data
# -------------------------------------------------------------------
def insertion_sort(items: list[T]) -> list[T]:
    """
    Build the sorted list one element at a time by "inserting" each
    new element into its correct position among the already-sorted
    prefix.

    Time:  O(n^2) worst/average, O(n) best.
    Space: O(1).
    Stable: yes.

    INTERVIEW NOTE:
    - Timsort uses insertion sort on small runs because its constant
      factors are *tiny* and it has near-linear performance on
      already-sorted input. Real-world data is often nearly sorted.
    """
    arr = list(items)
    for i in range(1, len(arr)):
        current = arr[i]
        j = i - 1
        # Shift larger elements one slot to the right to make space.
        while j >= 0 and arr[j] > current:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = current
    return arr


# -------------------------------------------------------------------
# 4. Merge Sort -- O(n log n). The "safe" answer.
# -------------------------------------------------------------------
def merge_sort(items: list[T]) -> list[T]:
    """
    Classic divide-and-conquer: split in half, sort each half,
    merge the two sorted halves.

    Time:  O(n log n) for all cases.
    Space: O(n) -- needs an auxiliary buffer for the merge.
    Stable: yes.

    INTERVIEW NOTE:
    - Merge sort is the textbook example of *recursion + divide and
      conquer*. The recurrence is T(n) = 2T(n/2) + O(n), which by
      the Master Theorem gives O(n log n).
    - It's stable and predictable -- no worst case like quicksort's
      O(n^2). The downside is the O(n) extra memory.
    - For an interview, write the helper `_merge` cleanly and use
      indices i, j, k to track positions in left, right, and output.
    """
    # Base case: a list of 0 or 1 element is already sorted.
    if len(items) <= 1:
        return list(items)

    mid = len(items) // 2
    left = merge_sort(items[:mid])
    right = merge_sort(items[mid:])
    return _merge(left, right)


def _merge(left: list[T], right: list[T]) -> list[T]:
    """
    Merge two already-sorted lists into one sorted list.
    The "<=" (not "<") is what makes merge sort STABLE.
    """
    merged: list[T] = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            merged.append(left[i])
            i += 1
        else:
            merged.append(right[j])
            j += 1
    # One side may have leftovers. `list.extend` is O(k) for k extras.
    merged.extend(left[i:])
    merged.extend(right[j:])
    return merged


# -------------------------------------------------------------------
# 5. Quicksort -- O(n log n) average, O(n^2) worst
# -------------------------------------------------------------------
def quick_sort(items: list[T]) -> list[T]:
    """
    Pick a pivot, partition the rest into "less than" and "greater
    than", recurse on each part.

    Time:  O(n log n) average, O(n^2) worst (bad pivots on sorted data).
    Space: O(log n) for the recursion stack on average.
    Stable: no (this implementation builds new lists, so technically
                yes -- but the classic in-place version is not).

    INTERVIEW NOTE:
    - "Why is quicksort O(n^2) worst case?" -> when every pivot is
      the smallest or largest element (e.g., already-sorted input
      with first-element pivot). Mitigations: median-of-three,
      randomized pivot, or just use median.
    - The version below is "Lomuto-lite": readable but not in-place.
      Mention that in-place Lomuto/Hoare partitioning is what
      production libraries use to save memory.
    """
    if len(items) <= 1:
        return list(items)

    # Choosing the middle element as pivot avoids worst case on
    # already-sorted input (which a first-element pivot would hit).
    pivot = items[len(items) // 2]

    # Three buckets in a single pass via list comprehensions.
    # This is O(n) time, O(n) extra space.
    less    = [x for x in items if x <  pivot]
    equal   = [x for x in items if x == pivot]
    greater = [x for x in items if x >  pivot]

    return quick_sort(less) + equal + quick_sort(greater)


# -------------------------------------------------------------------
# 6. "Sort by custom comparator" -- functools.cmp_to_key
# -------------------------------------------------------------------
def sort_by_comparator_demo() -> None:
    """
    Modern Python sorts use `key=` (a function that maps each element
    to a comparable value), NOT a comparator (like Java's Comparator).

    But sometimes the order can't be expressed as a key (e.g., the
    "largest number" problem: given [3, 30, 34, 5, 9], arrange them
    to form the largest number "9534330").

    `functools.cmp_to_key` bridges the gap: it converts a classic
    -1/0/+1 comparator into a key function.
    """
    from functools import cmp_to_key

    def compare(a: str, b: str) -> int:
        # Whichever concatenation order produces the larger result wins.
        # Returning negative means "a should come first".
        if a + b > b + a:
            return -1
        if a + b < b + a:
            return 1
        return 0

    nums = [3, 30, 34, 5, 9]
    biggest = "".join(sorted(map(str, nums), key=cmp_to_key(compare)))
    print(f"largest concat -> {biggest}")   # -> "9534330"


# -------------------------------------------------------------------
# Demo
# -------------------------------------------------------------------
def _demo() -> None:
    data = [5, 2, 9, 1, 5, 6, 3, 8, 4, 7, 1]
    print(f"original     : {data}")
    print(f"bubble       : {bubble_sort(data)}")
    print(f"insertion    : {insertion_sort(data)}")
    print(f"merge        : {merge_sort(data)}")
    print(f"quick        : {quick_sort(data)}")
    print(f"built-in     : {sorted(data)}")
    print("---")
    builtin_examples()
    print("---")
    sort_by_comparator_demo()


if __name__ == "__main__":
    _demo()
