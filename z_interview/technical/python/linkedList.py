#!/usr/bin/env python3
"""
linkedList.py
-------------
Singly linked list -- a CLASSIC interview question. You should be able
to write the Node + LinkedList classes, plus reverse / detect-cycle /
find-middle, on a whiteboard in 10 minutes.

WHY ASKED:
- Tests pointer/reference reasoning.
- Probes recursion and iterative thinking.
- Tests understanding of edge cases: empty list, single-node list,
  head/tail handling.
- In Python, lists already exist -- so the question is really about
  showing you understand the *underlying* node-and-pointer structure.

KEY TALKING POINTS:
- Time complexity of indexed access: O(n) for linked list vs O(1)
  for a Python `list` (which is actually a dynamic ARRAY under the hood).
- Insertion at HEAD is O(1), insertion at TAIL is O(n) unless you
  cache the tail.
- A doubly linked list lets you traverse backward and delete in O(1)
  given a node reference -- it's what `collections.deque` uses.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Generic, Iterator, Optional, TypeVar

T = TypeVar("T")


# -------------------------------------------------------------------
# Node
#
# INTERVIEW NOTE:
# - `@dataclass` saves you ~10 lines of boilerplate.
# - We DO NOT use `frozen=True` here because we mutate `.next` to
#   splice nodes together.
# - The `next: Optional["Node[T]"]` annotation uses a string ("Node")
#   for the forward reference because `Node` isn't fully defined yet
#   on that line. `from __future__ import annotations` (top of file)
#   actually makes ALL annotations strings, so this would work without
#   the explicit quotes -- but the quotes still help readers.
# -------------------------------------------------------------------
@dataclass
class Node(Generic[T]):
    value: T
    # `field(default=None)` is required (not `next: ... = None`) because
    # mutable / complex defaults need to be declared this way in dataclasses.
    next: Optional["Node[T]"] = field(default=None)


# -------------------------------------------------------------------
# Linked List
# -------------------------------------------------------------------
class LinkedList(Generic[T]):
    """
    Singly linked list with O(1) head and O(1) tail insertion (we
    cache a tail pointer), plus O(n) search and middle/cycle helpers.
    """

    def __init__(self) -> None:
        # Underscore prefix is the Python convention for "internal, but
        # not strictly private". A single leading underscore tells
        # readers "don't poke at this from outside".
        self._head: Optional[Node[T]] = None
        self._tail: Optional[Node[T]] = None
        self._size: int = 0

    # ---------- Dunder methods (make the class feel "pythonic") ----------

    def __len__(self) -> int:
        """`len(my_list)` works because of __len__."""
        return self._size

    def __iter__(self) -> Iterator[T]:
        """
        `for x in my_list:` works because of __iter__.
        INTERVIEW NOTE: defining __iter__ unlocks list comprehensions,
        unpacking, conversion via list(my_list), and all of the
        itertools machinery -- for free.
        """
        curr = self._head
        while curr is not None:
            yield curr.value
            curr = curr.next

    def __repr__(self) -> str:
        """Debug-friendly representation."""
        return "LinkedList([" + " -> ".join(repr(v) for v in self) + "])"

    def __contains__(self, value: T) -> bool:
        """`if x in my_list:` works because of __contains__."""
        # We could `return any(v == value for v in self)`, but a
        # manual loop is just as clear and arguably faster.
        for v in self:
            if v == value:
                return True
        return False

    # ---------- Insertion ----------

    def prepend(self, value: T) -> None:
        """Insert at HEAD. O(1)."""
        new_node = Node(value, next=self._head)
        self._head = new_node
        # If the list was empty, the new node is also the tail.
        if self._tail is None:
            self._tail = new_node
        self._size += 1

    def append(self, value: T) -> None:
        """Insert at TAIL. O(1) because we cache the tail."""
        new_node = Node(value)
        if self._tail is None:
            # Empty list -- both head and tail point at the new node.
            self._head = self._tail = new_node
        else:
            self._tail.next = new_node
            self._tail = new_node
        self._size += 1

    # ---------- Deletion ----------

    def remove(self, value: T) -> bool:
        """
        Remove the FIRST occurrence of `value`. Returns True if found.
        O(n) -- we have to scan.

        INTERVIEW NOTE:
        - The classic trick: keep a `prev` pointer one node behind
          `curr` so we can re-link `prev.next = curr.next`.
        - Watch out for: empty list, removing the head (no prev),
          removing the tail (must update _tail).
        """
        prev: Optional[Node[T]] = None
        curr = self._head
        while curr is not None:
            if curr.value == value:
                if prev is None:
                    # Removing the head.
                    self._head = curr.next
                else:
                    prev.next = curr.next
                if curr is self._tail:
                    # Removing the tail: prev becomes the new tail.
                    self._tail = prev
                self._size -= 1
                return True
            prev, curr = curr, curr.next
        return False

    # ---------- Classic interview operations ----------

    def reverse(self) -> None:
        """
        Reverse the list IN PLACE in O(n) time, O(1) extra space.

        INTERVIEW NOTE:
        - This is *the* canonical pointer-manipulation question.
        - Three pointers: prev, curr, next_tmp. We walk forward, but
          at each step we flip curr.next to point backwards.
        - Edge cases: empty (head is None) and single-element are
          handled naturally by the loop.
        """
        prev: Optional[Node[T]] = None
        curr = self._head
        # After the reverse, the old head will be the new tail.
        self._tail = self._head
        while curr is not None:
            next_tmp = curr.next        # save the next node
            curr.next = prev            # flip the pointer
            prev = curr                 # advance prev
            curr = next_tmp             # advance curr
        self._head = prev               # prev is the new head

    def middle(self) -> Optional[T]:
        """
        Return the middle value using the SLOW/FAST POINTER technique.
        For even-length lists, returns the upper-middle element.

        INTERVIEW NOTE:
        - Slow advances 1 node per step, fast advances 2. When fast
          hits the end, slow is at the middle. O(n) time, O(1) space.
        - This trick generalizes: same idea detects cycles
          (Floyd's algorithm, see has_cycle below).
        """
        slow = fast = self._head
        while fast is not None and fast.next is not None:
            slow = slow.next        # type: ignore[union-attr]
            fast = fast.next.next
        return slow.value if slow is not None else None

    def has_cycle(self) -> bool:
        """
        Detect a cycle using Floyd's Tortoise-and-Hare algorithm.
        O(n) time, O(1) space.

        INTERVIEW NOTE:
        - If a cycle exists, the fast pointer (2 steps) will
          eventually lap the slow pointer (1 step) and they'll meet.
        - If no cycle, fast hits None first.
        - The alternative -- using a `set()` of visited nodes -- is
          O(n) space. Always prefer Floyd's if asked about space.
        """
        slow = fast = self._head
        while fast is not None and fast.next is not None:
            slow = slow.next        # type: ignore[union-attr]
            fast = fast.next.next
            if slow is fast:
                return True
        return False


# -------------------------------------------------------------------
# Demo
# -------------------------------------------------------------------
def _demo() -> None:
    ll: LinkedList[int] = LinkedList()
    for v in [1, 2, 3, 4, 5]:
        ll.append(v)
    ll.prepend(0)
    print(ll)                           # LinkedList([0 -> 1 -> 2 -> 3 -> 4 -> 5])
    print(f"len     = {len(ll)}")
    print(f"middle  = {ll.middle()}")   # 3
    print(f"3 in ll = {3 in ll}")        # True

    ll.remove(3)
    print(f"after remove(3): {ll}")

    ll.reverse()
    print(f"after reverse  : {ll}")


if __name__ == "__main__":
    _demo()
