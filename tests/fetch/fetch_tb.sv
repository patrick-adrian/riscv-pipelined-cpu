`timescale 1ns/1ps

`include "control_macros.sv"

module fetch_tb;

    logic clk;
    always #5 clk = ~clk;

    // Waveform dump for post-sim viewing
    initial begin
        $dumpfile("fetch_stage_tb.vcd");
        $dumpvars(0, fetch_tb);
    end

    fetch_if vif(clk);

    // Simple cycle counter for logging
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

    fetch_env env;

    initial begin
        clk = 0;
        vif.reset = 1;
        repeat(2) @(posedge clk);
        vif.reset = 0;

        env = new(vif);
        env.run();

        #500 $finish;
    end

endmodule

