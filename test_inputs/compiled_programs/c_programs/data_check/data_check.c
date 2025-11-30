#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int x = 5;
int y = 7;

int main(void) {
    printf("Running Data Check\n");

    int sum = x + y;
    if (sum == 12)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
