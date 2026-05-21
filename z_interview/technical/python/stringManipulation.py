#!/usr/bin/env python3
"""
stringManipulation.py
---------------------
String questions dominate intern-level coding interviews. Every one
of these has appeared at AMD/Intel/NVIDIA-class companies dozens of
times. Memorize the PATTERNS, not the specific problems.

KEY PYTHON FACTS ABOUT STRINGS:
- Strings are IMMUTABLE. Any operation that "modifies" a string
  actually returns a new string. Concatenating in a loop is O(n^2);
  build a list and `"".join(list)` instead -- this is O(n).
- Strings are SEQUENCES: indexing, slicing, `in`, and iteration all
  work just like with lists.
- Comparison is by Unicode code point. `"a" < "b"` is True.
- `ord(c)` -> int code point;  `chr(i)` -> single-character string.
"""

from __future__ import annotations
from collections import Counter


# -------------------------------------------------------------------
# 1. Reverse a string
# -------------------------------------------------------------------
def reverse_string(s: str) -> str:
    """
    Return `s` reversed.

    INTERVIEW NOTE:
    - `s[::-1]` is the one-liner. O(n) time, O(n) space.
    - Strings being immutable means there's NO in-place reverse in
      pure Python without first converting to a list (`list(s)`).
    - If you'd want true in-place, you'd need `bytearray` (which is
      mutable). That detail wins you bonus points.
    """
    return s[::-1]


# -------------------------------------------------------------------
# 2. Palindrome check
# -------------------------------------------------------------------
def is_palindrome(s: str, ignore_case: bool = True, alnum_only: bool = True) -> bool:
    """
    Is `s` a palindrome ("racecar", "A man a plan a canal Panama")?

    INTERVIEW NOTE:
    - The "is it the same as its reverse?" one-liner is O(n) but
      allocates a full reversed copy.
    - The two-pointer version below is O(n) time, O(1) extra space.
      Interviewers usually want the two-pointer version once they
      see you reach for `[::-1]`.
    - REAL palindrome questions almost always ask you to ignore
      case and non-alphanumeric characters. Clarify this in the
      interview before you start writing.
    """
    if alnum_only:
        # Generator expression keeps the filtering lazy.
        s = "".join(c for c in s if c.isalnum())
    if ignore_case:
        s = s.lower()

    left, right = 0, len(s) - 1
    while left < right:
        if s[left] != s[right]:
            return False
        left += 1
        right -= 1
    return True


# -------------------------------------------------------------------
# 3. Anagram check
# -------------------------------------------------------------------
def is_anagram(a: str, b: str) -> bool:
    """
    Two strings are anagrams if one is a rearrangement of the other.

    INTERVIEW NOTE:
    - Lazy approach: `sorted(a) == sorted(b)`. O(n log n) time.
    - Better:        `Counter(a) == Counter(b)`. O(n) time.
    - The Counter approach is also generalizable: it's how you'd
      check if one string contains all characters of another, etc.
    """
    if len(a) != len(b):                # quick reject; saves work
        return False
    return Counter(a) == Counter(b)


# -------------------------------------------------------------------
# 4. First non-repeating character
# -------------------------------------------------------------------
def first_unique_char(s: str) -> int:
    """
    Return the index of the first character in `s` that appears only
    once, or -1 if no such character exists.

    INTERVIEW NOTE:
    - One pass to count, one pass to find the first count == 1.
      O(n) time, O(k) space where k is the alphabet size.
    - The single-pass version that only walks the string ONCE is
      a fun follow-up: use an OrderedDict (or dict, which is ordered
      since Python 3.7) keyed by character with values being either
      the index or a sentinel for "seen more than once".
    """
    counts = Counter(s)
    for i, c in enumerate(s):
        if counts[c] == 1:
            return i
    return -1


# -------------------------------------------------------------------
# 5. Longest substring without repeating characters (SLIDING WINDOW)
# -------------------------------------------------------------------
def length_of_longest_unique_substring(s: str) -> int:
    """
    Classic SLIDING WINDOW problem. O(n) time, O(k) space.

    INTERVIEW NOTE:
    - The sliding-window pattern uses two indices: `left` (window
      start) and `right` (window end). You expand `right`, and
      whenever the window becomes invalid, you advance `left`.
    - This is THE interview pattern for "longest/shortest substring
      with property X". Once you spot the pattern, half the solution
      is already done.
    - The `seen` dict maps char -> most recent index. When we hit a
      repeat that's inside the current window, jump `left` past it.
    """
    seen: dict[str, int] = {}
    left = 0
    best = 0
    for right, ch in enumerate(s):
        if ch in seen and seen[ch] >= left:
            # Skip past the previous occurrence -- crucial that we
            # use `max` so `left` never moves backward.
            left = seen[ch] + 1
        seen[ch] = right
        best = max(best, right - left + 1)
    return best


# -------------------------------------------------------------------
# 6. Word frequency in a sentence
# -------------------------------------------------------------------
def word_frequencies(text: str, top_n: int = 5) -> list[tuple[str, int]]:
    """
    Tokenize `text` and return the top-N words by frequency.

    INTERVIEW NOTE:
    - `Counter.most_common(n)` is the idiomatic top-N pattern. It
      uses a heap internally -- O(n log k) for top-k, NOT
      O(n log n).
    - In production you'd use a real tokenizer (regex `\\w+`,
      NLTK, etc.) -- `.split()` won't strip punctuation.
    """
    words = text.lower().split()
    return Counter(words).most_common(top_n)


# -------------------------------------------------------------------
# 7. String compression ("aaabbc" -> "a3b2c1")
# -------------------------------------------------------------------
def compress(s: str) -> str:
    """
    Run-length encode `s`. Return the original if encoding makes it
    longer (common variant of the question).

    INTERVIEW NOTE:
    - This is THE poster-child for "build a list, then ''.join()".
      Concatenating strings in a loop would be O(n^2).
    - Sentinel pattern: prime the loop by treating the first char
      as the "current" group. Saves an `if first iteration` check.
    """
    if not s:
        return s
    parts: list[str] = []
    current = s[0]
    count = 1
    # itertools.groupby is even cleaner, but the explicit version
    # is what an interviewer can follow on a whiteboard.
    for ch in s[1:]:
        if ch == current:
            count += 1
        else:
            parts.append(f"{current}{count}")
            current = ch
            count = 1
    parts.append(f"{current}{count}")

    encoded = "".join(parts)
    # Common follow-up: only return compressed if it's actually shorter.
    return encoded if len(encoded) < len(s) else s


# -------------------------------------------------------------------
# 8. Integer <-> string (atoi / itoa) -- low level, hardware-friendly
# -------------------------------------------------------------------
def atoi(s: str) -> int:
    """
    Convert a decimal string to an int WITHOUT using `int()`.

    INTERVIEW NOTE:
    - Real `atoi`-style questions usually want you to handle
      whitespace, optional sign, overflow clamping, etc. This
      version handles the basics; clarify scope with the interviewer.
    - The key trick is `result = result * 10 + (ord(ch) - ord('0'))`.
      This is EXACTLY what hardware does -- shift left in base 10,
      add the new digit. Hardware-flavored interviewers love this.
    """
    s = s.strip()
    if not s:
        raise ValueError("empty string")
    sign = 1
    i = 0
    if s[0] in "+-":
        if s[0] == "-":
            sign = -1
        i = 1
    result = 0
    while i < len(s) and s[i].isdigit():
        result = result * 10 + (ord(s[i]) - ord("0"))
        i += 1
    if i == (1 if sign != 1 or s[0] == "+" else 0):
        raise ValueError(f"no digits in {s!r}")
    return sign * result


# -------------------------------------------------------------------
# Demo
# -------------------------------------------------------------------
def _demo() -> None:
    print(f"reverse('hello')        = {reverse_string('hello')!r}")
    print(f"is_palindrome('A man a plan a canal Panama') = "
          f"{is_palindrome('A man a plan a canal Panama')}")
    print(f"is_anagram('listen','silent')                = "
          f"{is_anagram('listen','silent')}")
    print(f"first_unique('leetcode')                     = "
          f"{first_unique_char('leetcode')}")
    print(f"longest_unique('abcabcbb')                   = "
          f"{length_of_longest_unique_substring('abcabcbb')}")
    print(f"top words ('the cat the dog the bird the cat'): "
          f"{word_frequencies('the cat the dog the bird the cat')}")
    print(f"compress('aaabbc')                           = "
          f"{compress('aaabbc')!r}")
    print(f"atoi('  -1234abc')                           = "
          f"{atoi('  -1234abc')}")


if __name__ == "__main__":
    _demo()
