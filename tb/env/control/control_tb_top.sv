`timescale 1ns/1ps
`include "control_macros.sv"

module tb_control;

    logic clk;

    control_env       env;
    control_base_test test_h;
    string            testname;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_control);
    end

    control_if vif(clk);

    initial begin
        vif.reset    = 1'b0;
        vif.tb_valid = 1'b0;
        vif.instr_de = 32'h0;
    end

    control_unit dut (
        .op_de_i            (vif.op_de),
        .funct3_de_i        (vif.funct3_de),
        .funct7_de_i        (vif.funct7_de),
        .imm_src_de_o       (vif.imm_src),
        .result_src_de_o    (vif.result_src),
        .branch_op_de_o     (vif.branch_op),
        .alu_src_de_o       (vif.alu_src),
        .pc_base_src_de_o   (vif.pc_base_src),
        .reg_write_de_o     (vif.reg_write),
        .mem_write_de_o     (vif.mem_write),
        .csr_we_de_o        (vif.csr_we),
        .alu_control_de_o   (vif.alu_control),
        .width_src_de_o     (vif.width_src),
        .csr_control_de_o   (vif.csr_control),
        .csr_src_de_o       (vif.csr_src)
    );

    task automatic run_test(string name);
        test_h = create_test(name, vif, env);
        if (test_h == null)
            $fatal(1, "Unknown test '%0s'", name);
        test_h.run();
    endtask

    initial begin
        if (!$value$plusargs("TEST=%s", testname))
            testname = "control_basic_instr_test";

        $display("Running test: %0s", testname);

        env = new(vif);
        env.run();
        run_test(testname);
        $finish;
    end

endmodule
