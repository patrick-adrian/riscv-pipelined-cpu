class decode_slice_base_test;

    protected virtual decode_slice_if vif;
    protected decode_slice_env       env;

    function new(virtual decode_slice_if vif, decode_slice_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    // Tests can call this explicitly when they want a bubble/recovery cycle
    // around reset; the reset helpers below do not change interface controls.
    task drive_idle_controls();
        vif.stall              = 1'b1;
        vif.flush              = 1'b0;
        vif.instr_fi           = 32'h0;
        vif.pc_fi              = 32'h0;
        vif.pc_plus4_fi        = 32'h4;
        vif.pred_pc_target_fi  = 32'h0;
        vif.pc_src_pred_fi     = 1'b0;
    endtask

    // Canonical reset contract for this synchronous-reset DUT:
    // - Drive reset on negedge so it is stable before the next posedge.
    // - Do not constrain the other interface fields while reset is high.
    // - Hold reset high across the requested number of posedges.
    // - Deassert on negedge; tests that want a quiet recovery bubble must drive
    //   those controls explicitly.
    task assert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b1;
        $display("[TIME %0t] RESET ASSERTED", $time);
    endtask

    task deassert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b0;
        $display("[TIME %0t] RESET DEASSERTED", $time);
    endtask

    task pulse_reset(int cycles = 1);
        assert_reset();
        repeat (cycles) @(posedge vif.clk);
        deassert_reset();
    endtask

    task apply_reset(int cycles = 1);
        pulse_reset(cycles);
    endtask

    task send_txn(
        logic        stall,
        logic        flush,
        logic [31:0] instr,
        logic [31:0] pc
    );
        decode_slice_txn t;

        t = new();
        t.stall = stall;
        t.flush = flush;
        t.instr = instr;
        t.pc    = pc;
        env.put_txn(t);
    endtask

    virtual task run();
        $fatal(1, "decode_slice_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass
