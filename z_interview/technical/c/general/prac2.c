Q1 — What is wrong with this function? Fix it.
char* read_line(int max) {
    char buf[1024];						//on the stack
    int c, i = 0;

    while ((c = getchar()) != '\n' && c != EOF && i < max) {	//does not flush buffer
        buf[i++] = c;
    }

    buf[i] = '\0';
    return buf;
}

--------------------------------------------------------------------------------------------
SOLUTION:

char* read_line(int max) {

    char *buf = malloc(max+1);	//put onto heap
    if(!buf) return NULL;	//safety
	
    int c, i = 0;

    while ((c = getchar()) != '\n' && c != EOF) {
	if(i<max){		//flush buffer at last iteration or EOF
        	buf[i++] = c;
	}			
    }

    buf[i] = '\0';
    return buf;
}
