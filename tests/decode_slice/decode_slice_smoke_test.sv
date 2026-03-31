class decode_slice_smoke_test extends ds_base_test;

    function new(virtual ds_if vif, ds_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        ds_txn t;

        // ---- TXN 0: Reset clears the pipeline register ----
        t = new();
        t.reset = 1'b1;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h00000013;         // NOP (don't-care during reset)
        t.pc    = 32'h0000_0000;
        env.put_txn(t);

        // ---- TXN 1: NOP – ADDI x0, x0, 0 (I-type) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h00000013;         // imm_src=I_EXT, imm=0
        t.pc    = 32'h0000_0000;
        env.put_txn(t);

        // ---- TXN 2: ADDI x1, x0, 42 (I-type ALU) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h02A00093;         // imm_src=I_EXT, imm=42
        t.pc    = 32'h0000_0004;
        env.put_txn(t);

        // ---- TXN 3: LW x2, 8(x1) (I-type load) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h0080A103;         // imm_src=I_EXT, imm=8
        t.pc    = 32'h0000_0008;
        env.put_txn(t);

        // ---- TXN 4: SW x2, 16(x1) (S-type) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h0020A823;         // imm_src=S_EXT, imm=16
        t.pc    = 32'h0000_000C;
        env.put_txn(t);

        // ---- TXN 5: BEQ x1, x2, 8 (B-type) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h00208463;         // imm_src=B_EXT, imm=8
        t.pc    = 32'h0000_0010;
        env.put_txn(t);

        // ---- TXN 6: LUI x3, 0xDEADB (U-type) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'hDEADB1B7;         // imm_src=U_EXT, imm=0xDEADB000
        t.pc    = 32'h0000_0014;
        env.put_txn(t);

        // ---- TXN 7: JAL x4, 256 (J-type) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h1000026F;         // imm_src=J_EXT, imm=256
        t.pc    = 32'h0000_0018;
        env.put_txn(t);

        // ---- TXN 8: ADD x7, x1, x2 (R-type, no meaningful immediate) ----
        t = new();
        t.reset = 1'b0;
        t.stall = 1'b0;
        t.flush = 1'b0;
        t.instr = 32'h002083B3;         // imm_src=NA_EXT (==I_EXT)
        t.pc    = 32'h0000_001C;
        env.put_txn(t);

        report_and_finish();
    endtask

endclass
