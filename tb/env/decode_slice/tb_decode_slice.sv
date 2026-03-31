`timescale 1ns/1ps
`include "control_macros.sv"

module tb_decode_slice;

    logic clk;
    logic reset_prev;

    ds_env       env;
    ds_base_test test_h;
    string       testname;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_decode_slice);
    end

    ds_if vif(clk);

    initial begin
        vif.cycle          = 0;
        vif.txn_id         = -1;
        vif.reset          = 1'b0;
        vif.stall          = 1'b1;
        vif.flush          = 1'b0;
        vif.instr_fi       = 32'h0;
        vif.pc_fi          = 32'h0;
        vif.pc_plus4_fi    = 32'h4;
        vif.pred_pc_target_fi = 32'h0;
        vif.pc_src_pred_fi = 1'b0;
        reset_prev         = 1'b0;
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

    // ---- Feedback wire: main_decoder closes the imm_src loop ----
    logic [2:0] imm_src_wire;

    decode_stage u_decode_stage (
        .clk_i               (clk),
        .reset_i             (vif.reset),
        .instr_fi_i          (vif.instr_fi),
        .pc_fi_i             (vif.pc_fi),
        .pc_plus4_fi_i       (vif.pc_plus4_fi),
        .pred_pc_target_fi_i (vif.pred_pc_target_fi),
        .pc_src_pred_fi_i    (vif.pc_src_pred_fi),
        .imm_src_de_i        (imm_src_wire),
        .stall_de_i          (vif.stall),
        .flush_de_i          (vif.flush),
        .instr_de_o          (vif.instr_de),
        .imm_ext_de_o        (vif.imm_ext_de),
        .pc_de_o             (vif.pc_de),
        .pc_plus4_de_o       (vif.pc_plus4_de),
        .pred_pc_target_de_o (vif.pred_pc_target_de),
        .csr_addr_de_o       (vif.csr_addr_de),
        .rd_de_o             (vif.rd_de),
        .rs1_de_o            (vif.rs1_de),
        .rs2_de_o            (vif.rs2_de),
        .op_de_o             (vif.op_de),
        .funct3_de_o         (vif.funct3_de),
        .funct7_de_o         (vif.funct7_de),
        .pc_src_pred_de_o    (vif.pc_src_pred_de),
        .valid_de_o          (vif.valid_de)
    );

    main_decoder u_main_decoder (
        .op           (vif.op_de),
        .imm_src_o    (imm_src_wire),
        .result_src_o (),
        .alu_op_o     (),
        .branch_op_o  (),
        .width_op_o   (),
        .alu_src_o    (),
        .pc_base_src_o(),
        .reg_write_o  (),
        .mem_write_o  (),
        .csr_we_o     ()
    );

    assign vif.imm_src = imm_src_wire;

    // ---- Test orchestration ----
    task automatic run_test(string name);
        test_h = create_test(name, vif, env);
        if (test_h == null)
            $fatal(1, "Unknown test '%0s'", name);
        test_h.run();
    endtask

    initial begin
        if (!$value$plusargs("TEST=%s", testname))
            testname = "decode_slice_smoke_test";

        $display("Running test: %0s", testname);

        env = new(vif);
        env.run();
        run_test(testname);
        $finish;
    end

endmodule
