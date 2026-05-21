#!/usr/bin/env python3
"""
reverseList.py
--------------
"Reverse a list" is a *classic* warm-up interview question. Interviewers
use it to probe:

  1. Do you know Python's built-ins (and when each is appropriate)?
  2. Can you reason about time/space complexity (Big-O)?
  3. Do you understand mutability vs. immutability, lazy vs. eager?
  4. Can you implement it yourself (in-place, recursive)?

This file shows FIVE distinct approaches, ordered roughly from
"most pythonic" to "most algorithmic". Be ready to discuss trade-offs.
"""

from __future__ import annotations
from typing import Iterator, TypeVar

# A "type variable" lets us write generic functions: the function works
# for a list of ints, list of strs, etc., and a type checker can verify
# the return type matches the input type.
T = TypeVar("T")


# -------------------------------------------------------------------
# 1. list.reverse() -> IN-PLACE, returns None
# -------------------------------------------------------------------
def reverse_in_place_builtin(items: list[T]) -> None:
    """
    Reverse a list IN PLACE using the built-in `.reverse()` method.

    Time:  O(n)  -- visits each element once
    Space: O(1)  -- no auxiliary list is allocated

    INTERVIEW NOTE:
    - `list.reverse()` MUTATES the original list and returns `None`.
      A common Python gotcha is `x = my_list.reverse()` -> x is None!
    - This is the right choice when you don't need the original order
      anymore and want to avoid allocating a second list.
    """
    items.reverse()


# -------------------------------------------------------------------
# 2. Slicing with [::-1] -> RETURNS A NEW LIST
# -------------------------------------------------------------------
def reverse_via_slice(items: list[T]) -> list[T]:
    """
    Return a NEW reversed list using extended slice syntax.

    Time:  O(n)
    Space: O(n)  -- a new list of the same size is allocated

    INTERVIEW NOTE:
    - The slice syntax is `sequence[start:stop:step]`. With step = -1
      and start/stop omitted, Python walks the sequence backwards.
    - Works on any sequence: list, tuple, str. (`"hello"[::-1] == "olleh"`)
    - It's a one-liner and very pythonic, but it allocates O(n) extra
      memory -- not free!
    """
    return items[::-1]


# -------------------------------------------------------------------
# 3. reversed() -> RETURNS A LAZY ITERATOR
# -------------------------------------------------------------------
def reverse_lazy(items: list[T]) -> Iterator[T]:
    """
    Return a lazy iterator over the list in reverse order.

    Time:  O(1) to *create* the iterator, O(n) to fully consume it
    Space: O(1)  -- no copy is made; iterator holds an index + reference

    INTERVIEW NOTE:
    - `reversed()` is the lazy alternative to `[::-1]`. It doesn't
      build a new list -- it yields one element at a time.
    - Great for "process in reverse without doubling memory": e.g.,
      streaming the tail of a huge log file.
    - To materialize into a list, the caller does `list(reversed(items))`.
    """
    return reversed(items)


# -------------------------------------------------------------------
# 4. Two-pointer swap -> IN-PLACE, MANUAL
# -------------------------------------------------------------------
def reverse_two_pointer(items: list[T]) -> None:
    """
    Reverse IN PLACE using the classic two-pointer algorithm.

    Time:  O(n)  -- exactly n/2 swaps
    Space: O(1)  -- only two indices

    INTERVIEW NOTE:
    - This is the algorithm interviewers actually want to see if
      they say "don't use built-ins". It demonstrates fluency with
      indices and the swap idiom.
    - `a, b = b, a` is Python's tuple-packing/unpacking swap. Under
      the hood, it builds a tuple on the right, then unpacks it into
      the variables on the left. No temp variable needed.
    """
    left, right = 0, len(items) - 1
    while left < right:
        items[left], items[right] = items[right], items[left]
        left += 1
        right -= 1


# -------------------------------------------------------------------
# 5. Recursive -> NEW LIST, ELEGANT BUT INEFFICIENT
# -------------------------------------------------------------------
def reverse_recursive(items: list[T]) -> list[T]:
    """
    Return a NEW reversed list using recursion.

    Time:  O(n^2)  -- each slice copies; this is the gotcha!
    Space: O(n)    -- call stack depth = n  (plus copies)

    INTERVIEW NOTE:
    - Looks elegant, but Python has NO tail-call optimization. On a
      list of ~1000 elements you risk hitting `RecursionError`.
    - Also: `items[1:]` makes a fresh copy each call, hence O(n^2).
    - Mention these caveats if you write it on a whiteboard! It
      shows you know the difference between "looks pretty" and
      "is fast".
    """
    if len(items) <= 1:
        return items
    # Recursive case: reverse the tail, then put the head at the end.
    return reverse_recursive(items[1:]) + [items[0]]


# -------------------------------------------------------------------
# Demo / sanity check
# -------------------------------------------------------------------
def _demo() -> None:
    original = [1, 2, 3, 4, 5]

    # Make COPIES to avoid mutating between demos.
    # `list(original)` and `original[:]` both create shallow copies.
    a = list(original)
    reverse_in_place_builtin(a)
    print(f"in_place_builtin : {a}")

    print(f"slice            : {reverse_via_slice(original)}")
    print(f"lazy (consumed)  : {list(reverse_lazy(original))}")

    b = list(original)
    reverse_two_pointer(b)
    print(f"two_pointer      : {b}")

    print(f"recursive        : {reverse_recursive(original)}")

    # Sanity: original was never mutated by the non-in-place versions.
    print(f"original intact  : {original}")


if __name__ == "__main__":
    _demo()
