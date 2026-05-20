/*
Q1 — Allocate inside a function
Write void alloc_int(int **p) that:
allocates space for a single int
sets that integer to 42
returns the allocated pointer via the double pointer
What is the correct implementation? What must NOT be done?
*/

void alloc (int **p) {
	*p = malloc(sizeof(int));
	if (*p == NULL) return;		//can't return NULL, function returns void
	**p = 42;
}