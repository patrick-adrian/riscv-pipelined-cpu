`timescale 1ns/1ps
`include "control_macros.sv"

module tb_fetch;

    import uvm_pkg::*;
    import fetch_uvm_pkg::*;

    logic clk;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_fetch);
    end

    fetch_if vif(clk);

    initial begin
        vif.reset          = 1'b1;
        vif.tb_valid       = 1'b0;
        vif.pc_src         = 2'd0;
        vif.stall          = 1'b1;
        vif.pc_target_ex   = 32'h0;
        vif.pc_plus4_ex    = 32'h0;
        vif.pred_pc_target = 32'h0;
    end

    fetch_stage dut (
        .clk_i              (clk),
        .reset_i            (vif.reset),
        .pc_src_i           (vif.pc_src),
        .stall_fi_i         (vif.stall),
        .pc_target_ex_i     (vif.pc_target_ex),
        .pc_plus4_ex_i      (vif.pc_plus4_ex),
        .pred_pc_target_fi_i(vif.pred_pc_target),
        .pc_fi_o            (vif.pc),
        .pc_plus4_fi_o      (vif.pc_plus4)
    );

    initial begin
        uvm_config_db#(virtual fetch_if)::set(null, "*", "vif", vif);
        run_test();
    end

endmodule
