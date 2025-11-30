#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

typedef struct {
    int a;
    int b;
} Item;

int compute(Item *arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++)
        sum += arr[i].a * arr[i].b;
    return sum;
}

Item items[10] = {
    {1,2}, {3,4}, {5,6}, {7,8},
    {9,10}, {11,12}, {13,14}, {15,16},
    {17,18}, {19,20}
};

int main(void) {
    printf("Running Combined Check\n");

    int result = compute(items, 10); // expected 770

    if (result == 1430)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
