Q6 — Swap two pointers
Write:
void swap(int **a, int **b);
So that two pointers in main get swapped.

----------------------------------------------------------

void swap (int **a, int **b){
	int *temp = *a;
	*a = *b;
	*b = temp;
}

----------------------------------------------------------
holy this is right