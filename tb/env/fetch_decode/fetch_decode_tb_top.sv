`timescale 1ns/1ps
`include "control_macros.sv"

module tb_fetch_decode;

    logic clk;

    fetch_decode_env       env;
    fetch_decode_base_test test_h;
    string                 testname;

    // Decode exports the raw funct7 field; the integrated control check only
    // consumes bit 5, so the testbench normalizes the rest before control sees it.
    logic [6:0] raw_funct7_d;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_fetch_decode);
    end

    fetch_decode_control_if #(
        .IMEM_DEPTH(64)
    ) vif(clk);

    initial begin
        // Default control stimulus that steers fetch/decode until a test drives it.
        vif.reset             = 1'b1;
        vif.is_new_txn        = 1'b0;
        vif.pc_src            = `PC_SRC_SEQ_F;
        vif.stall_fi          = 1'b0;
        vif.stall_de          = 1'b0;
        vif.flush_de          = 1'b0;
        vif.pc_target_ex      = 32'h0;
        vif.pc_plus4_ex       = 32'h0;
        vif.pred_pc_target_fi = 32'h0;
        vif.pc_src_pred_fi    = 1'b0;
        vif.clear_program();
    end

    // Fetch stage under test.
    fetch_stage u_fetch_stage (
        .clk_i               (clk),
        .reset_i             (vif.reset),
        .pc_src_i            (vif.pc_src),
        .stall_fi_i          (vif.stall_fi),
        .pc_target_ex_i      (vif.pc_target_ex),
        .pc_plus4_ex_i       (vif.pc_plus4_ex),
        .pred_pc_target_fi_i (vif.pred_pc_target_fi),
        .pc_fi_o             (vif.pc_f),
        .pc_plus4_fi_o       (vif.pc_plus4_f)
    );

    // Fetch next-PC calculation for scoreboard visibility.
    always_comb begin
        case (vif.pc_src)
            `PC_SRC_SEQ_F:    vif.pc_next_f = vif.pc_f + 32'd4;
            `PC_SRC_PRED_F:   vif.pc_next_f = vif.pred_pc_target_fi;
            `PC_SRC_SEQ_E:    vif.pc_next_f = vif.pc_plus4_ex;
            `PC_SRC_TARGET_E: vif.pc_next_f = vif.pc_target_ex;
            default:          vif.pc_next_f = 32'h0;
        endcase
    end

    // Fetch-side instruction memory model.
    instr_mem_model #(
        .DEPTH(64)
    ) u_instr_mem (
        .pc_i    (vif.pc_f),
        .instr_o (vif.instr_f),
        .prog_if (vif)
    );

    // Decode stage under test.
    decode_stage u_decode_stage (
        .clk_i               (clk),
        .reset_i             (vif.reset),
        .instr_fi_i          (vif.instr_f),
        .pc_fi_i             (vif.pc_f),
        .pc_plus4_fi_i       (vif.pc_plus4_f),
        .pred_pc_target_fi_i (vif.pred_pc_target_fi),
        .pc_src_pred_fi_i    (vif.pc_src_pred_fi),
        .imm_src_de_i        (vif.imm_src_ctrl),
        .stall_de_i          (vif.stall_de),
        .flush_de_i          (vif.flush_de),
        .instr_de_o          (vif.instr_d),
        .imm_ext_de_o        (vif.imm_d),
        .pc_de_o             (vif.pc_d),
        .pc_plus4_de_o       (vif.pc_plus4_d),
        .pred_pc_target_de_o (vif.pred_pc_target_d),
        .csr_addr_de_o       (vif.csr_addr_d),
        .rd_de_o             (vif.rd_d),
        .rs1_de_o            (vif.rs1_d),
        .rs2_de_o            (vif.rs2_d),
        .op_de_o             (vif.opcode_d),
        .funct3_de_o         (vif.funct3_d),
        .funct7_de_o         (raw_funct7_d),
        .pc_src_pred_de_o    (vif.pc_src_pred_d),
        .valid_de_o          (vif.valid_d)
    );

    // The control block only consumes funct7[5], so zero-fill the unused bits
    // to keep the integrated slice deterministic.
    assign vif.funct7_d = {6'b0, raw_funct7_d[5]};

    // Control unit driven from decode outputs.
    control_unit u_control_unit (
        .op_de_i            (vif.opcode_d),
        .funct3_de_i        (vif.funct3_d),
        .funct7_de_i        (vif.funct7_d),
        .imm_src_de_o       (vif.imm_src_ctrl),
        .result_src_de_o    (vif.result_src_ctrl),
        .branch_op_de_o     (vif.branch_op_ctrl),
        .alu_src_de_o       (vif.alu_src_ctrl),
        .pc_base_src_de_o   (vif.pc_base_src_ctrl),
        .reg_write_de_o     (vif.reg_write_ctrl),
        .mem_write_de_o     (vif.mem_write_ctrl),
        .csr_we_de_o        (vif.csr_we_ctrl),
        .alu_control_de_o   (vif.alu_control_ctrl),
        .width_src_de_o     (vif.width_src_ctrl),
        .csr_control_de_o   (vif.csr_control_ctrl),
        .csr_src_de_o       (vif.csr_src_ctrl)
    );

    task automatic run_test(string name);
        test_h = create_test(name, vif, env);
        if (test_h == null)
            $fatal(1, "Unknown test '%0s'", name);
        test_h.run();
    endtask

    initial begin
        if (!$value$plusargs("TEST=%s", testname))
            testname = "fetch_decode_imem_smoke_test";

        $display("Running test: %0s", testname);

        env = new(vif);
        env.run();
        run_test(testname);
        $finish;
    end

endmodule
