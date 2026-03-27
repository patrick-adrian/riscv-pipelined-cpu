`include "control_macros.sv"

class decode_smoke_test extends decode_base_test;

    function new(virtual decode_if vif, decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        // TXN 0: reset clears pipeline register
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

        // TXN 1: capture with I immediate model
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h0001_2345;
        t.pc_fi_i            = 32'h0000_0100;
        t.pc_plus4_fi_i     = 32'h0000_0104;
        t.pred_pc_target_fi = 32'h0000_0200;
        t.imm_src_de_i      = `I_EXT;
        env.put_txn(t);

        // TXN 2: capture with B immediate model
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h00F0_1123;
        t.pc_fi_i            = 32'h0000_0108;
        t.pc_plus4_fi_i     = 32'h0000_010C;
        t.pred_pc_target_fi = 32'h0000_0220;
        t.imm_src_de_i      = `B_EXT;
        env.put_txn(t);

        // TXN 3: capture with J immediate model
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'hDEAD_BEEF;
        t.pc_fi_i            = 32'h0000_0110;
        t.pc_plus4_fi_i     = 32'h0000_0114;
        t.pred_pc_target_fi = 32'h0000_0240;
        t.imm_src_de_i      = `J_EXT;
        env.put_txn(t);

        report_and_finish();
    endtask

endclass

