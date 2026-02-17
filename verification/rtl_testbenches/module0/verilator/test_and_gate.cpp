//comprehensive tb

#include <iostream>
#include <cassert>
#include <verilated.h>
#include "Vand_gate.h"

//TestBench Class!

class TestBench {
private:
    Vand_gate* dut;
    int test_count;
    int pass_count;
    int fail_count;

public:
    //Constructor
    TestBench() : test_count (0), pass_count (0), fail_count(0) {
        dut = new Vand_gate
    }

    //Destructor
    ~TestBench() {
        dut->final();
        delete dut;
    }

    //Verilator ports typically 8-bit
    void check_and(uint8_t a_val, uint8_t b_val, uint8_t expected) {
        dut->a = a_val;
        dut->b = b_val;
        dut->eval();

        test_count++;

        if (dut->y == expected) {
            pass_count++;
            std::cout << "[PASS] Test " << test_count
                      << ": a=" << (int)a_val << ", b=" (int)b_val
                      << ", y=" << (int)dut->y << " (expected " << (int)expected << ")" 
                      << std::endl;
        } else {
            fail_count++;
            // Use std::cerr for error output (separate from normal output)
            std::cerr << "[FAIL] Test " << test_count 
                      << ": a=" << (int)a_val << ", b=" << (int)b_val 
                      << ", y=" << (int)dut->y << " (expected " << (int)expected << ")" 
                      << std::endl;
        }
    }

    void run_tests() {
        check_and(0, 0, 0);  // Test case 1: Both inputs 0
        check_and(0, 1, 0);  // Test case 2: A=0, B=1
        check_and(1, 0, 0);  // Test case 3: A=1, B=0
        check_and(1, 1, 1);  // Test case 4: Both inputs 1

        if (fail_count == 0) {
            std::cout << "✓ All tests PASSED!" << std::endl;
        } else {
            std::cout << "✗ Some tests FAILED!" << std::endl;
        }
    }

    int get_fail_count() const { return fail_count; }
}

//Main
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    TestBench tb;
    tb.run_tests();

    return (tb.get_fail_count() == 0) ? 0 : 1;
}