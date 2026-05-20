Q9 — NULL safety

Rewrite this function to be safe:

void safe_free(int **p) {
    free(*p);
    *p = NULL;
}


What errors can occur if the caller misuses it?


---------------------------------------------------------

Dereferencing NULL pointer -> Crash (Seg fault), or Undefined behavior

void safe_free(int **p) {
    if (p && *p) {   // check both pointer-to-pointer and pointer
        free(*p);
        *p = NULL;
    }
}
