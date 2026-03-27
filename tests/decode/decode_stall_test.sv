`include "control_macros.sv"

class decode_stall_test extends decode_base_test;

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
        t.imm_src_de_i      = `I_EXT;
        env.put_txn(t);

        // TXN 1: capture instruction A
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h0123_4567;
        t.pc_fi_i            = 32'h0000_0100;
        t.pc_plus4_fi_i     = 32'h0000_0104;
        t.pred_pc_target_fi = 32'h0000_0200;
        t.imm_src_de_i      = `I_EXT;
        env.put_txn(t);

        // TXN 2: stall, provide different inputs but keep imm_src stable
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b1;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b0;
        t.instr_fi_i         = 32'h89AB_CDEF;
        t.pc_fi_i            = 32'h0000_0300;
        t.pc_plus4_fi_i     = 32'h0000_0304;
        t.pred_pc_target_fi = 32'h0000_0400;
        t.imm_src_de_i      = `I_EXT; // keep stable so imm_ext holds as well
        env.put_txn(t);

        // TXN 3: resume, capture instruction C
        t = new();
        t.reset              = 1'b0;
        t.stall              = 1'b0;
        t.flush              = 1'b0;
        t.pc_src_pred_fi     = 1'b1;
        t.instr_fi_i         = 32'h0BAD_C0DE;
        t.pc_fi_i            = 32'h0000_0110;
        t.pc_plus4_fi_i     = 32'h0000_0114;
        t.pred_pc_target_fi = 32'h0000_0250;
        t.imm_src_de_i      = `S_EXT;
        env.put_txn(t);

        report_and_finish();
    endtask

endclass

