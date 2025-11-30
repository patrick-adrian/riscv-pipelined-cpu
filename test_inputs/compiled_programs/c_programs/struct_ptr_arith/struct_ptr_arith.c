#include "csr_defs.h"
#include "stubs.h"
#include "test_status.h"

typedef struct {
    int a;
    int b;
} Pair;

int main(void) {
    printf("Running Struct Pointer Check\n");

    Pair p;
    p.a = 10;
    p.b = 20;

    if (p.a + p.b == 30)
        signal_test_pass();
    else
        signal_test_fail();

    while (1) { }
}
