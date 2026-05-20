typedef struct node {
    int val;
    struct node *next;
} node;

typedef struct queue {
    node *front;
    node *rear;
} queue;

---------------------------------------------------
void enqueue(queue *q, int value) {
    node *new_node = malloc(sizeof(node));
    new_node->val = value;
    new_node->next = NULL;

    if (!q->front) {
        // empty queue
        q->front = q->rear = new_node;
        return;
    }

    q->rear->next = new_node;
    q->rear = new_node;
}
------------------------------------------------------
int dequeue(queue *q) {
    if (!q->front) return -1;

    node *temp = q->front;
    int val = temp->val;

    q->front = q->front->next;
    if (!q->front)
        q->rear = NULL;

    free(temp);
    return val;
}
------------------------------------------------------------------------------------------
#define MAX 100

typedef struct {
    int arr[MAX];
    int front;
    int rear;
    int count;
} queue;
----------------------------- enqueue
q->arr[q->rear] = value;
q->rear = (q->rear + 1) % MAX;
q->count++;
------------------------------ dequeue
int val = q->arr[q->front];
q->front = (q->front + 1) % MAX;
q->count--;
