`timescale 1ns/1ps

`include "control_macros.sv"

// To run TB:
// cd ../\(1) fetch_stage/tb
// iverilog -g2012 fetch_tb_modular.sv ../fetch_stage.sv  -I ../../../../../common/ ../../../../../common/adder.sv ../../../../../common/flop.sv -o fetch_tb_modular.out
// vvp fetch_tb_modular.out
// gtkwave fetch_tb_modular.vcd

//Stimulus Module
module fetch_stage_stimulus(
    output logic        clk_i,
    output logic        reset_i,
    output logic [1:0]  pc_src_i,
    output logic        stall_fi_i,
    output logic [31:0] pc_target_ex_i,
    output logic [31:0] pc_plus4_ex_i,
    output logic [31:0] pred_pc_target_fi_i
);

    // Clock
    initial clk_i = 0;
    always #10 clk_i = ~clk_i;

    // Drive sequence
    initial begin
        // Defaults
        pc_src_i            = `PC_SRC_SEQ_F;
        stall_fi_i          = 0;
        pc_target_ex_i      = 32'hAAAA_0000;
        pc_plus4_ex_i       = 32'hBBBB_0000;
        pred_pc_target_fi_i = 32'hCCCC_0000;

        // Reset
        reset_i = 1;
        repeat (2) @(posedge clk_i);
        reset_i = 0;

        // Sequential increments
        repeat (3) @(posedge clk_i);

        // Branch prediction
        pc_src_i = `PC_SRC_PRED_F;
        @(posedge clk_i);

        // EX sequential
        pc_src_i = `PC_SRC_SEQ_E;
        @(posedge clk_i);

        // EX target
        pc_src_i = `PC_SRC_TARGET_E;
        @(posedge clk_i);

        // Stall test
        pc_src_i   = `PC_SRC_SEQ_F;
        stall_fi_i = 1;
        @(posedge clk_i);
        stall_fi_i = 0;

        #20 $finish;
    end

endmodule

//Monitor process
module fetch_stage_monitor(
    input logic        clk_i,
    input logic        reset_i,
    input logic [1:0]  pc_src_i,
    input logic        stall_fi_i,
    input logic [31:0] pc_target_ex_i,
    input logic [31:0] pc_plus4_ex_i,
    input logic [31:0] pred_pc_target_fi_i,
    input logic [31:0] pc_fi_o,
    input logic [31:0] pc_plus4_fi_o
);

always @(posedge clk_i) begin
    $display("[MONITOR] t=%0t | src=%0d stall=%0d | pc=%h pc+4=%h",
        $time, pc_src_i, stall_fi_i, pc_fi_o, pc_plus4_fi_o);
end

endmodule

//Checker
module fetch_stage_checker(
    input logic        clk_i,
    input logic        reset_i,
    input logic [1:0]  pc_src_i,
    input logic        stall_fi_i,
    input logic [31:0] pc_target_ex_i,
    input logic [31:0] pc_plus4_ex_i,
    input logic [31:0] pred_pc_target_fi_i,
    input logic [31:0] pc_fi_o
);

    logic [31:0] expected_pc;

    always @(posedge clk_i) begin
        if (reset_i) begin
            expected_pc <= 32'd0;
        end
        else if (!stall_fi_i) begin
            case (pc_src_i)
                `PC_SRC_SEQ_F:    expected_pc <= expected_pc + 4;
                `PC_SRC_PRED_F:   expected_pc <= pred_pc_target_fi_i;
                `PC_SRC_SEQ_E:    expected_pc <= pc_plus4_ex_i;
                `PC_SRC_TARGET_E: expected_pc <= pc_target_ex_i;
            endcase
        end

        // Compare
        if (!reset_i) begin
            if (pc_fi_o !== expected_pc) begin
                $display("❌ ERROR @ %0t | expected=%h got=%h",
                         $time, expected_pc, pc_fi_o);
                $fatal;
            end
        end
    end
endmodule

module fetch_tb;

    logic clk_i;
    logic reset_i;
    logic [1:0]  pc_src_i;
    logic        stall_fi_i;
    logic [31:0] pc_target_ex_i;
    logic [31:0] pc_plus4_ex_i;
    logic [31:0] pred_pc_target_fi_i;
    logic [31:0] pc_fi_o;
    logic [31:0] pc_plus4_fi_o;

    fetch_stage_stimulus stim (.*);

    fetch_stage dut (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .pc_src_i(pc_src_i),
        .stall_fi_i(stall_fi_i),
        .pc_target_ex_i(pc_target_ex_i),
        .pc_plus4_ex_i(pc_plus4_ex_i),
        .pred_pc_target_fi_i(pred_pc_target_fi_i),
        .pc_fi_o(pc_fi_o),
        .pc_plus4_fi_o(pc_plus4_fi_o)
    );

    fetch_stage_monitor mon (.*);

    fetch_stage_checker check (.*);

    initial begin
        $dumpfile("fetch_tb_modular.vcd");        
        $dumpvars(0, fetch_tb);             
        $dumpvars(1, dut);                         
    end

endmodule