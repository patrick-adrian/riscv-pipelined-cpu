#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

int main(void) {
    printf("Running Basic Check\n");

    // Optional debug CSR write if you want to see something in the log
    write_csr(CSR_MDBG, 1234u);

    signal_test_pass();
    while (1) { }
}
