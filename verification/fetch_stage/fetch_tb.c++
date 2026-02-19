#include <verilated.h>
#include "Vfetch_stage.h"

vluint64_t sim_time = 0;

double sc_time_stamp() {
    return sim_time;
}

// Toggle clock helper
void tick(Vfetch_stage* dut) {
    dut->clk_i = 0;
    dut->eval();
    sim_time++;

    dut->clk_i = 1;
    dut->eval();
    sim_time++;
}

int main(int argc, char** argv) {

    Verilated::commandArgs(argc, argv);
    Vfetch_stage* dut = new Vfetch_stage;

    // -------------------------------
    // Initialize inputs
    // -------------------------------
    dut->reset_i = 1;
    dut->stall_fi_i = 0;

    dut->pc_src_i = 0;
    dut->pc_target_ex_i = 0xAAAA0000;
    dut->pc_plus4_ex_i  = 0xBBBB0000;
    dut->pred_pc_target_fi_i = 0xCCCC0000;

    // Apply reset for 2 cycles
    tick(dut);
    tick(dut);

    dut->reset_i = 0;

    // -----------------------------------
    // 1. Sequential (PC + 4)
    // -----------------------------------
    dut->pc_src_i = 0; // PC_SRC_SEQ_F
    tick(dut);

    uint32_t expected = 0x00000000;

    if (dut->pc_fi_o != expected) {
        printf("ERROR: Expected %08x, got %08x\n",
               expected, dut->pc_fi_o);
        return 1;
    }

    for (int i = 0; i < 2; i++) {
        expected += 4;
        tick(dut);

        if (dut->pc_fi_o != expected) {
            printf("ERROR: Expected %08x, got %08x\n",
                   expected, dut->pc_fi_o);
            return 1;
        }
    }

    // -----------------------------------
    // 2. Branch prediction source
    // -----------------------------------
    dut->pc_src_i = 1; // PC_SRC_PRED_F
    expected = dut->pred_pc_target_fi_i;

    tick(dut);

    if (dut->pc_fi_o != expected) {
        printf("ERROR: Branch prediction failed\n");
        return 1;
    }

    // -----------------------------------
    // 3. EX sequential redirect
    // -----------------------------------
    dut->pc_src_i = 2; // PC_SRC_SEQ_E
    expected = dut->pc_plus4_ex_i;

    tick(dut);

    if (dut->pc_fi_o != expected) {
        printf("ERROR: EX seq redirect failed\n");
        return 1;
    }

    // -----------------------------------
    // 4. EX target redirect
    // -----------------------------------
    dut->pc_src_i = 3; // PC_SRC_TARGET_E
    expected = dut->pc_target_ex_i;

    tick(dut);

    if (dut->pc_fi_o != expected) {
        printf("ERROR: EX target redirect failed\n");
        return 1;
    }

    // -----------------------------------
    // 5. Stall test
    // -----------------------------------
    dut->pc_src_i = 0;
    dut->stall_fi_i = 1;

    tick(dut);

    if (dut->pc_fi_o != expected) {
        printf("ERROR: Stall failed\n");
        return 1;
    }

    printf("All tests PASSED.\n");

    dut->final();
    delete dut;
    return 0;
}