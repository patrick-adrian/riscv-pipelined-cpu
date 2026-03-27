`include "control_macros.sv"

class decode_precedence_test extends decode_base_test;

    function new(virtual decode_if vif, decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        // TXN 0: start with reset
        decode_txn t = new();
        t.reset              = 1'b1;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h0;
        t.pc_fi_i            = 32'h0;
        t.pc_plus4_fi_i     = 32'h4;
        t.pred_pc_target_fi = 32'h0;
        t.imm_src_de_i      = `I_EXT;
        env.put_txn(t);

        // TXN 1: capture with stall=0
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h0A0B_0C0D;
        t.pc_fi_i            = 32'h0000_0100;
        t.pc_plus4_fi_i     = 32'h0000_0104;
        t.pred_pc_target_fi = 32'h0000_0200;
        t.imm_src_de_i      = `U_EXT;
        env.put_txn(t);

        // TXN 2: flush asserted while stalled (flush should clear regardless of stall)
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b1;
        t.flush              = 1'b1;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h2222_3333;
        t.pc_fi_i            = 32'h0000_0300;
        t.pc_plus4_fi_i     = 32'h0000_0304;
        t.pred_pc_target_fi = 32'h0000_0400;
        t.imm_src_de_i      = `B_EXT;
        env.put_txn(t);

        // TXN 3: reset asserted while stalled (reset should clear regardless of stall)
        t = new();
        t.reset              = 1'b1;
        t.stall              = 1'b1;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h4444_5555;
        t.pc_fi_i            = 32'h0000_0500;
        t.pc_plus4_fi_i     = 32'h0000_0504;
        t.pred_pc_target_fi = 32'h0000_0600;
        t.imm_src_de_i      = `J_EXT;
        env.put_txn(t);

        // TXN 4: recover after reset/flush
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'hDEAD_0001;
        t.pc_fi_i            = 32'h0000_0108;
        t.pc_plus4_fi_i     = 32'h0000_010C;
        t.pred_pc_target_fi = 32'h0000_0220;
        t.imm_src_de_i      = `CSR_EXT;
        env.put_txn(t);

        report_and_finish();
    endtask

endclass

