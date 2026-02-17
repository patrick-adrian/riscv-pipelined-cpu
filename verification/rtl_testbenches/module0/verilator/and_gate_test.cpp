//Simple and gate tb

#include <iostream>
#include <cassert>
#include <verilated.h>
#include "Vand_gate.h"

int main(int argc, char** argv){

    Verilated::commandArgs(argc, argv); //process CLI arguments for verilator options

    std::cout <<"And Gate TB" << std::end1;

    Vand_gate* dut - new Vand_gate;

    // Test table header
    std::cout << "\nTesting AND gate truth table:" << std::endl;
    std::cout << "  a  |  b  |  y  | Expected" << std::endl;
    std::cout << "-----|-----|-----|----------" << std::endl;

    // test procedure
    dut->a = 0;  // Set input A to 0
    dut->b = 0;  // Set input B to 0
    dut->eval(); // Evaluate combinational logic

    std::cout << "  " << (int)dut->a << "  |  " << (int)dut->b 
              << "  |  " << (int)dut->y << "  |    0" << std::endl;

    // Assert: verify output is correct (aborts if false)
    assert(dut->y == 0 && "Test failed: 0 & 0 should be 0");

    // Test completion message
    std::cout << "\n========================================" << std::endl;
    std::cout << "All tests passed!" << std::endl;
    std::cout << "========================================" << std::endl;

    dut->final();  // Cleanup
    delete dut;     // Free memory
    
    return 0;  // Exit successfully

}