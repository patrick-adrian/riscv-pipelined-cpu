`timescale 1ns/1ps
`include "control_macros.sv"

module tb_control_unit;

    control_env       env;
    control_base_test test_h;
    string            testname;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_control_unit);
    end

    control_if vif();

    initial begin
        vif.valid  = 1'b0;
        vif.txn_id = -1;
        vif.opcode = 7'b0;
        vif.funct3 = 3'b0;
        vif.funct7 = 7'b0;
    end

    control_unit dut (
        .op_de_i            (vif.opcode),
        .funct3_de_i        (vif.funct3),
        .funct7_de_i        (vif.funct7),
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
