#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int deep(int x) {
    if (x == 0) return 1;
    return deep(x - 1) + 1;
}

int main(void) {
    printf("Running Deep Recursion\n");

    int result = deep(200); // expected 201

    if (result == 201)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
