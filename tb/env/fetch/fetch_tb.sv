`timescale 1ns/1ps

`include "control_macros.sv"

// Reusable fetch testbench harness: clock, interface, DUT, cycle counter.
// Test logic (reset, env, transactions) lives in tests/fetch/*.sv
module fetch_tb;

    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, fetch_tb);
    end

    fetch_if vif(clk);

    initial vif.cycle = 0;
    always @(posedge clk) begin
        if (vif.reset)
            vif.cycle <= 0;
        else
            vif.cycle <= vif.cycle + 1;
    end

    fetch_stage dut (
        .clk_i(clk),
        .reset_i(vif.reset),
        .pc_src_i(vif.pc_src),
        .stall_fi_i(vif.stall),
        .pc_target_ex_i(vif.pc_target_ex),
        .pc_plus4_ex_i(vif.pc_plus4_ex),
        .pred_pc_target_fi_i(vif.pred_pc_target),
        .pc_fi_o(vif.pc),
        .pc_plus4_fi_o(vif.pc_plus4)
    );

endmodule
