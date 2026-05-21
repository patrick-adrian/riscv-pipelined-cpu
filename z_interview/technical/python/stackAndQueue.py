#!/usr/bin/env python3
"""
stackAndQueue.py
----------------
Stacks (LIFO) and Queues (FIFO) underpin a HUGE number of real systems:
  - Function call frames -> stack
  - DFS traversal       -> stack
  - BFS traversal       -> queue
  - Pipelined CPU       -> queues at every stage boundary (FIFOs)
  - Out-of-order issue  -> reservation stations + ROB (sort of like
                            indexed queues)

WHY YOU MIGHT GET THIS IN AN AMD INTERVIEW:
- Hardware engineers think about FIFOs constantly. Showing you know
  the software analog -- and Python's right tool for the job -- is
  table stakes.
- Classic question: "Implement a queue using two stacks" or "Design
  a stack that supports getMin() in O(1)."

PYTHON CHEAT SHEET:
- `list` is a dynamic array. `.append()` and `.pop()` (from the END)
  are amortized O(1). But `.pop(0)` (from the FRONT) is O(n) because
  every other element must shift. NEVER use `list` as a queue.
- `collections.deque` is a double-ended queue implemented as a
  doubly-linked list of blocks. Both ends are O(1). USE THIS FOR
  QUEUES.
- `queue.Queue` is thread-safe but heavier. Use it only when you
  actually need cross-thread synchronization.
"""

from __future__ import annotations
from collections import deque
from typing import Generic, TypeVar

T = TypeVar("T")


# -------------------------------------------------------------------
# 1. Stack -- a thin wrapper over list
# -------------------------------------------------------------------
class Stack(Generic[T]):
    """
    LIFO stack. We wrap `list` for a cleaner API (push/pop/peek).

    INTERVIEW NOTE:
    - In real code, most pythonistas just use `list` directly with
      `.append()` and `.pop()`. The wrapper is here to show what a
      stack IS conceptually.
    - All operations are O(1) amortized.
    """

    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, value: T) -> None:
        self._items.append(value)

    def pop(self) -> T:
        # We let `IndexError` propagate on empty pop -- explicit is
        # better than returning a magic None. Some implementations
        # raise a custom `EmptyStackError` instead; both are fine.
        if not self._items:
            raise IndexError("pop from empty stack")
        return self._items.pop()

    def peek(self) -> T:
        if not self._items:
            raise IndexError("peek from empty stack")
        return self._items[-1]

    def __len__(self) -> int:
        return len(self._items)

    def __bool__(self) -> bool:
        """
        INTERVIEW NOTE:
        - Defining __bool__ lets `if my_stack:` work naturally.
        - If __bool__ is missing, Python falls back to __len__ != 0,
          so for this class we get the same behavior. We define it
          explicitly to be clear about intent.
        """
        return bool(self._items)


# -------------------------------------------------------------------
# 2. Queue -- a thin wrapper over collections.deque
# -------------------------------------------------------------------
class Queue(Generic[T]):
    """
    FIFO queue backed by `deque`.

    INTERVIEW NOTE:
    - `deque.append(x)`     -> enqueue at the right
    - `deque.popleft()`     -> dequeue from the left
    - Both are O(1). This is what makes deque the right structure.
    """

    def __init__(self) -> None:
        self._items: deque[T] = deque()

    def enqueue(self, value: T) -> None:
        self._items.append(value)

    def dequeue(self) -> T:
        if not self._items:
            raise IndexError("dequeue from empty queue")
        return self._items.popleft()

    def peek(self) -> T:
        if not self._items:
            raise IndexError("peek from empty queue")
        return self._items[0]

    def __len__(self) -> int:
        return len(self._items)


# -------------------------------------------------------------------
# 3. MinStack -- "design a stack with O(1) getMin()"
# -------------------------------------------------------------------
class MinStack:
    """
    A stack that supports push/pop/top/getMin all in O(1).

    INTERVIEW NOTE: THE TRICK
    -------------------------
    Maintain a *parallel stack* of "the minimum so far". When you
    push x, also push min(x, current_min) onto the min stack. On
    pop, pop both. Then getMin() is just min_stack[-1].

    Trade-off: O(n) extra space. There are clever O(1)-extra-space
    variants using bit tricks or storing differences, but the
    interviewer almost always wants the simple two-stack solution
    first.
    """

    def __init__(self) -> None:
        self._stack: list[int] = []
        # Each entry in `_mins` is the min of everything in `_stack`
        # up to and including the same index.
        self._mins: list[int] = []

    def push(self, x: int) -> None:
        self._stack.append(x)
        new_min = x if not self._mins else min(x, self._mins[-1])
        self._mins.append(new_min)

    def pop(self) -> int:
        self._mins.pop()
        return self._stack.pop()

    def top(self) -> int:
        return self._stack[-1]

    def get_min(self) -> int:
        return self._mins[-1]


# -------------------------------------------------------------------
# 4. Queue implemented with two stacks (classic question)
# -------------------------------------------------------------------
class QueueFromStacks(Generic[T]):
    """
    Implement a FIFO queue using only two LIFO stacks.

    INTERVIEW NOTE:
    - `_in`  receives all pushes.
    - When you need to dequeue, drain `_in` into `_out` (which
      reverses the order, turning FIFO into LIFO-of-LIFO = FIFO).
    - Each element is moved at most TWICE (in -> out -> popped),
      giving AMORTIZED O(1) per operation. Worst-case single
      operation is O(n), but the *average* over a sequence is O(1).
    - The amortized-analysis argument is what the interviewer is
      really probing here. Be ready to explain it.
    """

    def __init__(self) -> None:
        self._in: list[T] = []
        self._out: list[T] = []

    def enqueue(self, value: T) -> None:
        self._in.append(value)

    def dequeue(self) -> T:
        if not self._out:
            # Drain only when _out is empty. This is the key to
            # the amortized analysis -- we don't drain on every op.
            while self._in:
                self._out.append(self._in.pop())
        if not self._out:
            raise IndexError("dequeue from empty queue")
        return self._out.pop()

    def __len__(self) -> int:
        return len(self._in) + len(self._out)


# -------------------------------------------------------------------
# 5. Practical use: balanced parentheses with a stack
# -------------------------------------------------------------------
def is_balanced(s: str) -> bool:
    """
    Check whether parentheses/brackets/braces in `s` are balanced.

    INTERVIEW NOTE:
    - Canonical "stack" warm-up. Walk the string; push on open,
      compare-and-pop on close. The stack must be EMPTY at the end.
    - The dict-based lookup is cleaner than chained if/elif blocks
      and trivially extends to new bracket types.
    """
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[str] = []
    for ch in s:
        if ch in "([{":
            stack.append(ch)
        elif ch in ")]}":
            # Close-without-matching-open OR mismatched -> unbalanced.
            if not stack or stack[-1] != pairs[ch]:
                return False
            stack.pop()
    return not stack            # leftover opens -> unbalanced


# -------------------------------------------------------------------
# Demo
# -------------------------------------------------------------------
def _demo() -> None:
    s: Stack[int] = Stack()
    for x in [1, 2, 3]:
        s.push(x)
    print(f"stack pop: {s.pop()}, peek: {s.peek()}, len: {len(s)}")

    q: Queue[str] = Queue()
    for w in ["a", "b", "c"]:
        q.enqueue(w)
    print(f"queue dequeue: {q.dequeue()}, peek: {q.peek()}, len: {len(q)}")

    ms = MinStack()
    for x in [3, 5, 2, 8, 2, 1]:
        ms.push(x)
    print(f"min stack getMin = {ms.get_min()}")  # 1
    ms.pop()
    print(f"after pop, getMin = {ms.get_min()}") # 2

    qs: QueueFromStacks[int] = QueueFromStacks()
    for x in [10, 20, 30]:
        qs.enqueue(x)
    print(f"two-stack queue dequeue: {qs.dequeue()}")   # 10
    qs.enqueue(40)
    print(f"two-stack queue dequeue: {qs.dequeue()}")   # 20

    for test in ["()[]{}", "(]", "([{}])", "((("]:
        print(f"balanced {test!r:>10} -> {is_balanced(test)}")


if __name__ == "__main__":
    _demo()
