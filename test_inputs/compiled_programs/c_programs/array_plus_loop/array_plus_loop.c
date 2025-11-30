#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int arr[100];

int main(void) {
    printf("Running Array and Loop Check\n");

    for (int i = 0; i < 100; i++)
        arr[i] = i * 3;

    if (arr[20] == 60)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
