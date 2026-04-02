`include "control_macros.sv"

class decode_reset_test extends decode_base_test;

    function new(virtual decode_if vif, decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        // TXN 0: reset
        decode_txn t = new();
        t.reset              = 1'b1;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h0;
        t.pc_fi_i            = 32'h0;
        t.pc_plus4_fi_i     = 32'h4;
        t.pred_pc_target_fi = 32'h0;
        t.imm_src_de_i      = `U_EXT;
        env.put_txn(t);

        // TXN 1: capture after reset deassert
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h1357_9BDF;
        t.pc_fi_i            = 32'h0000_0100;
        t.pc_plus4_fi_i     = 32'h0000_0104;
        t.pred_pc_target_fi = 32'h0000_0200;
        t.imm_src_de_i      = `I_EXT;
        env.put_txn(t);

        // TXN 2: assert reset again while also stalling (reset must win)
        t = new();
        t.reset              = 1'b1;
        t.stall              = 1'b1;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'hAAAA_5555;
        t.pc_fi_i            = 32'h0000_0300;
        t.pc_plus4_fi_i     = 32'h0000_0304;
        t.pred_pc_target_fi = 32'h0000_0400;
        t.imm_src_de_i      = `S_EXT;
        env.put_txn(t);

        // TXN 3: capture after reset release
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h2468_ACE0;
        t.pc_fi_i            = 32'h0000_0108;
        t.pc_plus4_fi_i     = 32'h0000_010C;
        t.pred_pc_target_fi = 32'h0000_0220;
        t.imm_src_de_i      = `CSR_EXT;
        env.put_txn(t);

        report_and_finish();
    endtask

endclass

