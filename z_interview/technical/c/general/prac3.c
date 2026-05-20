Q2 — What does this code print? Explain why.
int main() {
    int a = 10;
    int b = 20;
    int *p = &a;
    int *q = p;

    *q = 5;
    p = &b;
    *p = 7;

    printf("%d %d %d\n", a, b, *q);
}

--------------------------------------------------------------------
SOLUTION:

int main() {
    int a = 10;
    int b = 20;
    int *p = &a;	//*p = a
    int *q = p;		//*q = a

    *q = 5;		//a = 5
    p = &b;		//*p = b
    *p = 7;		//b = 7

    printf("%d %d %d\n", a, b, *q);
}

a = 5, b = 7, *q=a=5