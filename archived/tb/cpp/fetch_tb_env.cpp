#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vfetch_stage.h"

#include <iostream>
#include <cstdlib>
#include <ctime>

// To run TB:
// cd ../\(1)fetch_stage/tb
// verilator -Wall -cc ../fetch_stage.sv ../../../../../common/adder.sv ../../../../../common/flop.sv --exe fetch_tb_env.cpp --build --trace
// ./obj_dir/Vfetch_stage 
// gtkwave fetch_tb_env.vcd

vluint64_t sim_time = 0;

double sc_time_stamp() {
    return sim_time;
}

// Golden reference model
class FetchModel {
public:
    uint32_t pc = 0;

    void reset() {
        pc = 0;
    }

    void update(uint8_t pc_src,
                bool stall,
                uint32_t pc_target_ex,
                uint32_t pc_plus4_ex,
                uint32_t pred_pc_target) {

        if (stall) return;

        uint32_t next_pc = 0;

        switch (pc_src) {
            case 0: // PC_SRC_SEQ_F
                next_pc = pc + 4;
                break;

            case 1: // PC_SRC_PRED_F
                next_pc = pred_pc_target;
                break;

            case 2: // PC_SRC_SEQ_E
                next_pc = pc_plus4_ex;
                break;

            case 3: // PC_SRC_TARGET_E
                next_pc = pc_target_ex;
                break;

            default:
                next_pc = 0;
        }

        pc = next_pc;
    }
};

// In UVM the env bundles:
// agent (driver, sequencer, monitor), and scoreboard
class FetchEnv {
public:
    Vfetch_stage* dut;
    VerilatedVcdC* tfp;
    FetchModel model;

    FetchEnv() {
        dut = new Vfetch_stage;

        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        dut->trace(tfp, 99);
        tfp->open("waveform.vcd");

        // Initialize inputs
        dut->clk_i = 0;
        dut->reset_i = 0;
        dut->stall_fi_i = 0;
        dut->pc_src_i = 0;
        dut->pc_target_ex_i = 0;
        dut->pc_plus4_ex_i = 0;
        dut->pred_pc_target_fi_i = 0;
    }

    ~FetchEnv() {
        tfp->close();
        delete dut;
    }

    void tick() {
        dut->clk_i = 0;
        dut->eval();
        tfp->dump(sim_time++);

        dut->clk_i = 1;
        dut->eval();
        tfp->dump(sim_time++);
    }

    void reset() {
        dut->reset_i = 1;

        for (int i = 0; i < 5; i++)
            tick();

        dut->reset_i = 0;

        model.reset();
    }

    void step_and_check() {

        // Compute expected next state BEFORE clock edge
        model.update(
            dut->pc_src_i,
            dut->stall_fi_i,
            dut->pc_target_ex_i,
            dut->pc_plus4_ex_i,
            dut->pred_pc_target_fi_i
        );

        tick();

        // Check PC
        if (dut->pc_fi_o != model.pc) {
            std::cout << "PC mismatch at time "
                      << sim_time
                      << "\nExpected: " << model.pc
                      << "\nGot:      " << dut->pc_fi_o
                      << std::endl;
            exit(1);
        }

        // Check PC+4 output
        if (dut->pc_plus4_fi_o != model.pc + 4) {
            std::cout << "PC+4 mismatch at time "
                      << sim_time
                      << "\nExpected: " << model.pc + 4
                      << "\nGot:      " << dut->pc_plus4_fi_o
                      << std::endl;
            exit(1);
        }
    }
};

void test_seq_fetch(FetchEnv& env) {
    std::cout << "Running sequential fetch test...\n";

    env.dut->pc_src_i = 0; // PC_SRC_SEQ_F
    env.dut->stall_fi_i = 0;

    for (int i = 0; i < 10; i++)
        env.step_and_check();
}

void test_predictor(FetchEnv& env) {
    std::cout << "Running predictor test...\n";

    env.dut->pc_src_i = 1; // PC_SRC_PRED_F
    env.dut->stall_fi_i = 0;
    env.dut->pred_pc_target_fi_i = 0x200;

    env.step_and_check();
}

void test_seq_ex(FetchEnv& env) {
    std::cout << "Running EX sequential test...\n";

    env.dut->pc_src_i = 2; // PC_SRC_SEQ_E
    env.dut->pc_plus4_ex_i = 0x300;
    env.dut->stall_fi_i = 0;

    env.step_and_check();
}

void test_target_ex(FetchEnv& env) {
    std::cout << "Running EX target test...\n";

    env.dut->pc_src_i = 3; // PC_SRC_TARGET_E
    env.dut->pc_target_ex_i = 0x400;
    env.dut->stall_fi_i = 0;

    env.step_and_check();
}

void test_stall(FetchEnv& env) {
    std::cout << "Running stall test...\n";

    env.dut->pc_src_i = 0;
    env.dut->stall_fi_i = 0;
    env.step_and_check();

    uint32_t frozen = env.model.pc;

    env.dut->stall_fi_i = 1;

    for (int i = 0; i < 5; i++) {
        env.step_and_check();
        if (env.model.pc != frozen) {
            std::cout << "Model changed during stall!\n";
            exit(1);
        }
    }

    env.dut->stall_fi_i = 0;
}

void test_random(FetchEnv& env) {
    std::cout << "Running random stress test...\n";

    std::srand(std::time(nullptr));

    for (int i = 0; i < 2000; i++) {

        env.dut->pc_src_i = rand() % 4;
        env.dut->stall_fi_i = rand() % 2;

        env.dut->pc_target_ex_i = (rand() % 256) * 4;
        env.dut->pc_plus4_ex_i = (rand() % 256) * 4;
        env.dut->pred_pc_target_fi_i = (rand() % 256) * 4;

        env.step_and_check();
    }
}

int main(int argc, char** argv) {

    Verilated::commandArgs(argc, argv);

    FetchEnv env;

    env.reset();

    test_seq_fetch(env);
    test_predictor(env);
    test_seq_ex(env);
    test_target_ex(env);
    test_stall(env);
    test_random(env);

    std::cout << "\nAll fetch stage tests PASSED\n";

    return 0;
}