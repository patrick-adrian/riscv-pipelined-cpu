class fetch_base_test;

    protected virtual fetch_if vif;
    protected fetch_env env;

    function new(virtual fetch_if vif, fetch_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    // Tests can call this explicitly when they want a bubble/recovery cycle
    // around reset; the reset helpers below do not change interface controls.
    task drive_idle_controls();
        vif.pc_src         = 2'd0;
        vif.stall          = 1'b1;
        vif.pc_target_ex   = 32'h0;
        vif.pc_plus4_ex    = 32'h0;
        vif.pred_pc_target = 32'h0;
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
    endtask

    task deassert_reset();
        @(negedge vif.clk);
        vif.reset = 1'b0;
    endtask

    task pulse_reset(int cycles = 1);
        assert_reset();
        repeat (cycles) @(posedge vif.clk);
        deassert_reset();
    endtask

    task apply_reset(int cycles = 1);
        pulse_reset(cycles);
    endtask

    virtual task run();
        $fatal(1, "fetch_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        env.report_results();
    endtask

endclass
