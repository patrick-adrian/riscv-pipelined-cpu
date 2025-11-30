#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int foo(int x) { return x + 10; }
int bar(int x) { return x * 2; }

int main(void) {
    printf("Running Function Pointer Check\n");

    int (*fp)(int) = foo;
    if (fp(5) != 15)
        signal_test_fail();

    fp = bar;
    if (fp(5) != 10)
        signal_test_fail();

    // If we got here, both checks passed
    signal_test_pass();

    while (1) { }
}
