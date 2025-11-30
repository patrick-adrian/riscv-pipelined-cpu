#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int A[200];              // .bss
int B[200] = {1, 2, 3};  // .data

int main(void) {
    printf("Running Global Array\n");

    A[0] = 10;

    if (B[2] + A[0] == 13)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
