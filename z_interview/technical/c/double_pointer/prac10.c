Q5 — Modify caller’s pointer
What does this program print?

void change(int **p) {
    static int x = 10;		//static makes it persist
				//initializes it only once, persists subsequent calls
				//global lifetime, scope is still local to function
				//not heap, "global/static memory area"
				//safe cause it doesn't live on the stack
				//MUST NEVER BE FREED
    *p = &x;
}

int main() {
    int a = 5;
    int *p = &a;

    change(&p);
    printf("%d\n", *p);
}
---------------------------------------------------------------------------------------

