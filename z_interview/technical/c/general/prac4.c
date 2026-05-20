Q3 — Predict the output + explain lifetime issues
char* weird() {
    char *p = malloc(5);		//on the heap
    char temp[] = "Hello";		//local array, on the stack
    for (int i = 0; i < 5; i++)
        p[i] = temp[i];			//no null terminator for p
					//p is never returned?
    return temp;			//returning something from the stack, undefined

}

------------------------------------------------------------------------------------------
SOLUTION:

char* weird() {
    	char temp[] = "hello";
	char *p = malloc(strlen(temp)+1);
	//char *p = malloc(sizeof(temp));

	if(!p) return NULL;

	strcpy(p, temp);
	return p;
	
}
