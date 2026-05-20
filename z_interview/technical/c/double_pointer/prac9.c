Q4 — Returning a dynamically allocated string
Explain the problem with this code:

char* make() {
    char str[] = "hey";
    return str;
}

Rewrite it correctly using heap allocation.

--------------------------------------------------------------------------------

char* make(int n) {
    char* str = malloc(n*sizeof(char));
    if (!str) return NULL;

    strcpy(str, "hey");

    return str;
}