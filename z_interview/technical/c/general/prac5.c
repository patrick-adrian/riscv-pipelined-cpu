Q4 — What does the following print, and what’s wrong with it?
void weird2(int **p) {
    int x = 10;
    *p = &x;
}

int main() {
    int *q = NULL;
    weird2(&q);
    printf("%d\n", *q);
}

---------------------------------------------------------------
SOLUTION:

int main() {
    int *q = NULL;		//pointer q is null
    weird2(&q);			//pass pointer to pointer q to weird2
				//weird2(address of pointer q -> pointer q -> q)
    printf("%d\n", *q);
}

void weird2(&q) {
    int x = 10;			//this is on the stack
    *q = &x;			//pointer q now points to pointer x ---> 10
}

//but when weird2() ends, memory in stack invalid --> x is undefined --> *q now points to undefined/dead memory
//might contain garbage

-------------------------------------------------------------------------
FIXED:

void weird2(int **p) {
    int *x = malloc(sizeof(int));
    *x = 10;
    *p = &x;
     //OR
     *p = malloc(sizeof(int));
      *p = 10;
}

int main() {
    int *q = NULL;
    weird2(&q);
    printf("%d\n", *q);
    //eventually free(q);
}