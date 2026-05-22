struct node {
	int val;
	struct node *next;
}

struct node *head = NULL;
struct node n1;

--------------------------------------------------------------------------
typedef struct node {
	int val;
	struct node *next;
} node;

node *head = NULL;
node n1;

--------------------------------------------------------------------------------------------
void reverse(node **head) {
    node *prev = NULL, *curr = *head, *next;

    while (curr) {
        next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }

    *head = prev;
}

-----------------------------------------------------------------------------
void push_front(node **head, int value) {
	if(!head) return;

	node *new_node = malloc(sizeof(node));
	if(!new_node) return;

	new_node->val = value;
	new_node->next = *head;
	*head = new_node;
}

--------------------------------------------------------------------------------
void push_back(node **head, int value) {
	
	if(!head) return;

	node *new_node = malloc(sizeof(node));
	if(!new_node) return;
	new_node->val = value;
	new_node->next = NULL;
	

	if(*head==NULL) {
		*head = new_node;
		return;
	}

	node *curr = *head;
	while (curr->next !=NULL){
		curr = curr->next;
	}

	curr->next = new_node;

}

---------------------------------------------------------------------------------------
int pop_front(node **head) {
    if (!head || !*head) return -1; // empty list

    node *temp = *head;
    int val = temp->val;
    *head = temp->next;
    free(temp);
    return val;
}

--------------------------------------------------------------------------------------------
int pop_back(node **head) {
    if (!head || !*head) return -1; // empty list

    node *curr = *head;
    if (!curr->next) {  // only one node
        int val = curr->val;
        free(curr);
        *head = NULL;
        return val;
    }

    // traverse to second-last node
    while (curr->next->next != NULL)
        curr = curr->next;

    int val = curr->next->val;
    free(curr->next);
    curr->next = NULL;
    return val;
}
--------------------------------------------------------------------------------------------

void delete_value(node **head, int value) {
    if (!head || !*head) return;

    node *curr = *head, *prev = NULL;

    while (curr) {
        if (curr->val == value) {
            if (prev)
                prev->next = curr->next;
            else
                *head = curr->next;  // deleting head

            free(curr);
            return;
        }
        prev = curr;
        curr = curr->next;
    }
}
--------------------------------------------------------------------------------------------
node* find(node *head, int value) {
    while (head) {
        if (head->val == value)
            return head;
        head = head->next;
    }
    return NULL;
}