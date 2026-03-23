class fetch_base_test;

    protected virtual fetch_if vif;
    protected fetch_env env;

    function new(virtual fetch_if vif, fetch_env env);
        this.vif = vif;
        this.env = env;
    endfunction

    task apply_reset(int cycles = 3);
        vif.reset = 1'b1;
        repeat (cycles) @(posedge vif.clk);
        vif.reset = 1'b0;
        repeat (1) @(posedge vif.clk);
    endtask

    virtual task run();
        $fatal(1, "fetch_base_test::run() must be overridden");
    endtask

    task report_and_finish();
        env.wait_for_completion();
        $display("Total checks: %0d", env.scoreboard.num_checked);
        $display("Mismatches: %0d", env.scoreboard.mismatch_count);
        if (env.scoreboard.mismatch_count == 0 &&
            env.scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAIL");
    endtask

endclass
