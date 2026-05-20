/*
Q2 — Fix the bug
What is wrong with this code?
*/

void make(char **p) {
    char buf[10];
    strcpy(buf, "hi");
    *p = buf;		//points to stack, undefined
}

----------------------------------------------------------------
void make(char **p) {
    char *buf = malloc(3);
    if(!buf) return;
    strcpy(buf, "hi");
    *p = buf;			//buf already a pointa
}