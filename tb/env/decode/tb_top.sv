`timescale 1ns/1ps
`include "control_macros.sv"

module tb_top;

    logic clk;
    logic reset_prev;

    decode_env        env;
    decode_base_test  test_h;
    string             testname;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

    decode_if vif(clk);

    initial begin
        vif.cycle              = 0;
        vif.txn_tag            = -1;
        vif.reset              = 1'b0;

        // Safe defaults before the first scheduled transaction.
        vif.pc_src_pred_fi     = 1'b0;
        vif.stall              = 1'b1;
        vif.flush              = 1'b0;
        vif.imm_src_de_i      = `I_EXT;

        vif.instr_fi_i         = 32'h0;
        vif.pc_fi_i            = 32'h0;
        vif.pc_plus4_fi_i     = 32'h0;
        vif.pred_pc_target_fi = 32'h0;

        reset_prev = 1'b0;
    end

    always @(posedge clk) begin
        if (vif.reset && !reset_prev)
            $display("[TIME %0t] RESET ASSERTED", $time);
        if (!vif.reset && reset_prev)
            $display("[TIME %0t] RESET DEASSERTED", $time);

        reset_prev <= vif.reset;

        if (vif.reset)
            vif.cycle <= 0;
        else
            vif.cycle <= vif.cycle + 1;
    end

    decode_stage dut (
        .clk_i              (clk),
        .reset_i            (vif.reset),
        .instr_fi_i        (vif.instr_fi_i),
        .pc_fi_i           (vif.pc_fi_i),
        .pc_plus4_fi_i     (vif.pc_plus4_fi_i),
        .pred_pc_target_fi_i(vif.pred_pc_target_fi),
        .pc_src_pred_fi_i   (vif.pc_src_pred_fi),
        .imm_src_de_i      (vif.imm_src_de_i),
        .stall_de_i        (vif.stall),
        .flush_de_i        (vif.flush),

        .instr_de_o        (vif.instr_de_o),
        .imm_ext_de_o      (vif.imm_ext_de_o),
        .pc_de_o           (vif.pc_de_o),
        .pc_plus4_de_o     (vif.pc_plus4_de_o),
        .pred_pc_target_de_o(vif.pred_pc_target_de_o),
        .csr_addr_de_o     (vif.csr_addr_de_o),
        .rd_de_o           (vif.rd_de_o),
        .rs1_de_o          (vif.rs1_de_o),
        .rs2_de_o          (vif.rs2_de_o),
        .op_de_o           (vif.op_de_o),
        .funct3_de_o       (vif.funct3_de_o),
        .funct7_de_o       (vif.funct7_de_o),
        .pc_src_pred_de_o  (vif.pc_src_pred_de_o),
        .valid_de_o        (vif.valid_de_o)
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
            testname = "decode_smoke_test";

        $display("Running test: %0s", testname);

        env = new(vif);
        env.run();
        run_test(testname);
        $finish;
    end

endmodule

