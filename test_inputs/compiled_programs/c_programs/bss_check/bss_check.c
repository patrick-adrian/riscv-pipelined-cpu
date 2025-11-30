#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int a;      // should be zero-initialized
int b = 3;  // .data

int main(void) {
    printf("Running BSS Check\n");

    if (a == 0 && b == 3)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
