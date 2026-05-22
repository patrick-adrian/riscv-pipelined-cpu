#Q9: Retry mechanism (VERY REALISTIC)

import time

def retry(func, max_attempts=3):
    for i in range(max_attempts):
        try:
            return func()
        except Exception:
            time.sleep(1)
    raise Exception("Failed after retries")