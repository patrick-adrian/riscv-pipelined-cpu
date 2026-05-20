Q8 — Deep bug detection

What’s the bug here?

void set(int **p) {
    int x = 100;
    *p = &x;
}

Explain what happens and how to fix it.
--------------------------------------------------------------------
void set(int **p) {
    int *x = malloc(sizeof(int));
    if (!*x) return;
     *x = 100;
    *p = &x;
}
----------------------------------------------------------
#include <stdlib.h>

void set(int **p) {
    *p = malloc(sizeof(int));
    if (!*p) return;   // always check for allocation failure
    **p = 100;
}

---------------------
OR use a static

void set(int **p) {
    static int x;
    x = 100;
    *p = &x;
}
