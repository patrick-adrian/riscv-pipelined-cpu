Q - INTERVIEW QUESTION
// The following code shows a C program. 
// The foo function is intended to take user input up to a certain number of characters and then return a character array containing those characters. 
// Please find and fix any issues within foo so that the function works as desired. 

#include <stdio.h> 
#define CONST_NAME 256 

int main() { 
	char* my_chars = foo(10); 
	printf(""%s"", my_chars); 
} 

char* foo(int my_arg){ 

	char chars[CONST_NAME]; 	//on the stack
	int my_int = 1; 		//starts index at 1?

	do { 
		c = getchar(); 
		chars[my_int]= c; 
		if(c =='\n') { 
			return chars; 	
		} 
	} while (my_int <= my_arg);
}

--------------------------------------------------------------------------------------------
SOLUTION:

char* foo(int my_arg){ 

	char* chars = malloc(my_arg+1); //+1 for null terminator. put on heap. if you return a pointing towards stack, it may be 					//gone
	if (!chars) return NULL;	//good practice

	int my_int = 0; 		//start at index 0

	int c;				//getchar returns an int
					//char normally holds values from 0-255 or -128 to 127
					//getchar can return 0-255 OR -1 (EOF)
					//if stored in char, -1 (EOF) could get misinterpreted
					//char can't reliable store EOF
					

	do { 
		c = getchar(); 	
		if(c =='\n') { 
			break;			
		} 
	
		chars[my_int]= (char) c; 	//converted to char
		
		my_int++;		//increment my_int to avoid infinite loop
		
	} while (my_int < my_arg);

	chars[my_int] = '\0';		//null terminator
	return chars;
}







