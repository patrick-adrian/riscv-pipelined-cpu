"""
Q10: Poll hardware status

Prompt:
Keep checking until device becomes READY.
"""

import time

def wait_for_ready(get_status):
    while True:
        if get_status() == "READY":
            return True
        time.sleep(0.5)