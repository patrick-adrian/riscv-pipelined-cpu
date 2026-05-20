Q10 — Linked list insertion
Implement:
void insert_front(node **head, int value);
Where:

typedef struct node {
    int val;
    struct node *next;
} node;
Insert at the front correctly using double pointers.
-----------------------------------------------------------------------------
#include <stdlib.h>

void insert_front(node **head, int value) {
    if (!head) return;

    node *new_node = malloc(sizeof(node));
    if (!new_node) return;  // allocation failed

    new_node->val = value;
    new_node->next = *head;
    *head = new_node;
}
