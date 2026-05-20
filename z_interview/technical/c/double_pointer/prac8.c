Q3 — Reallocate a buffer
Write a function:
void grow(char **p, int old, int new);

It:
takes a pointer to a heap buffer *p of size old
resizes it to size new
preserves original contents
updates the pointer
What is the correct implementation?
-----------------------------------------------------------------------------------------

void grow(char **p, int old, int new){
	char temp[old];
	strcpy(temp, *p);

	free(*p);

	*p = malloc(new);
	if(!*p) return;

	strcpy(*p, temp);
}
-------------------------------------------------------------------------------------

-we use double pointers when a function needs to modify a pointer in the caller rather than only access data
-T* lets you modify data at the address
-T** lets you modify the address
-dynamic allocation, reallocation, resizing a buffer, arrays of pointers, linked structures, 
-when a point itself is the thing that chages

void grow(char **p, int new) {
    char *newBuf = malloc(new);
    if (!newBuf) return;

    strcpy(newBuf, *p);
    free(*p);

    *p = newBuf;
}
