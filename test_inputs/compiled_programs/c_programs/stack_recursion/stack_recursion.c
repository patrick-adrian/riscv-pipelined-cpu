#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int fact(int x) {
    if (x <= 1) return 1;
    return x * fact(x - 1);
}

int main(void) {
    printf("Running Stack Recursion\n");

    int result = fact(5); // expected 120

    if (result == 120)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
