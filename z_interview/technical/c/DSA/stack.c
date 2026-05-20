typedef struct node {
	int value;
	struct node* next;
} node;
----------------------------------------------------
void push(node **top, int value){
	node *new_node = malloc(sizeof(node));
	new_node->val = val;
	new_node->next = *top;
	*top = new_node;
}
-----------------------------------------------------
int pop(node **top){
	if(!top || !*top){
		return -1;
	}

	int val = (*top)->value;
	node* tmp = *top;
	*top = tmp->next;
	free(tmp);
	return val;
}
------------------------------------------------------------------------------------------------------------
#define MAX 100

typedef struct {
    int arr[MAX];
    int top;
} stack;

----------------------------- push
s->arr[++s->top] = value;

----------------------------- pop
return s->arr[s->top--];


