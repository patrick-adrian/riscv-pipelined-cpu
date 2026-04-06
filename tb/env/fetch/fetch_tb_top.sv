`timescale 1ns/1ps
`include "control_macros.sv"

module tb_fetch;

    logic clk;
    fetch_env env;
    fetch_base_test test_h;
    string testname;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_fetch);
    end

    fetch_if vif(clk);

    initial begin
        vif.reset = 1'b0;
        vif.tb_valid = 1'b0;
        vif.pc_src = 2'd0;
        vif.stall = 1'b1;
        vif.pc_target_ex = 32'h0;
        vif.pc_plus4_ex = 32'h0;
        vif.pred_pc_target = 32'h0;
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

    task automatic run_test(string name);
        test_h = create_test(name, vif, env);
        if (test_h == null) begin
            $fatal(1, "Unknown test '%0s'", name);
        end
        test_h.run();
    endtask

    initial begin
        if (!$value$plusargs("TEST=%s", testname))
            testname = "fetch_smoke_test";

        $display("Running test: %0s", testname);

        env = new(vif);
        env.run();
        run_test(testname);
        $finish;
    end

endmodule
