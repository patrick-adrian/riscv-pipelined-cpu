Q7 — Classic interview problem

Write a function:
void push(int **arr, int *size, int value);

It:
grows an integer array by 1
inserts value at the end
updates both the pointer and the size
This is basically a tiny version of std::vector::push_back but in C.

------------------------------------------------------------------------------

void push(int **arr, int *size, int value){

	//*arr = realloc(*arr, (sizeof(*arr)+1)*sizeof(int)); //WRONG: size of pointer
	//*arr = realloc(*arr, (sizeof(**arr)+1)*sizeof(int)); //WRONG: size of first element
								//can't get size info
	*arr = realloc((*size+1)*sizeof(int)); //also valid

	if(!*arr) return;					//always check pointer

	(*arr)[*size] = value;

	(*size)++;

}
----------------------------------------------------------------------------------
#include <stdlib.h>

void push(int **arr, int *size, int value) {
    int *tmp = realloc(*arr, (*size + 1) * sizeof(int));
    if (!tmp) return;       // allocation failed, don't modify original array

    *arr = tmp;
    (*arr)[*size] = value;  // append at the old-size index
    (*size)++;
}
