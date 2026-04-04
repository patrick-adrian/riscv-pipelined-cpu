class control_env;

    virtual control_if vif;

    control_driver     driver;
    control_monitor    monitor;
    control_scoreboard scoreboard;

    mailbox #(control_txn) drv_mbx;
    mailbox #(control_obs) mon_mbx;

    int num_txns_sent = 0;
    int default_max_wait_cycles = 1_000;

    function new(virtual control_if vif);
        this.vif = vif;

        drv_mbx = new();
        mon_mbx = new();

        driver     = new(vif, drv_mbx);
        monitor    = new(vif, mon_mbx);
        scoreboard = new(mon_mbx);
    endfunction

    task run();
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none
    endtask

    task put_txn(control_txn txn);
        drv_mbx.put(txn);
        num_txns_sent++;
    endtask

    function bit has_failures();
        return scoreboard.mismatch_count != 0;
    endfunction

    task wait_for_completion(int max_wait_cycles = -1, int drain_cycles = 2);
        int waited;
        int target_checks;

        waited = 0;
        if (max_wait_cycles < 0) max_wait_cycles = default_max_wait_cycles;

        while (driver.num_sent < num_txns_sent) begin
            @(posedge vif.clk);
            waited++;
            if (waited >= max_wait_cycles)
                $fatal(1, "Timeout waiting for driver: drove=%0d queued=%0d mismatches=%0d",
                       driver.num_sent, num_txns_sent, scoreboard.mismatch_count);
        end

        repeat (drain_cycles) @(posedge vif.clk);

        target_checks = monitor.num_sampled;
        waited        = 0;
        while (scoreboard.num_checked < target_checks) begin
            @(posedge vif.clk);
            waited++;
            if (waited >= max_wait_cycles)
                $fatal(1, "Timeout waiting for scoreboard: checked=%0d sampled=%0d mismatches=%0d",
                       scoreboard.num_checked, target_checks, scoreboard.mismatch_count);
        end
    endtask

    task report_results();
        $display("=== CONTROL UNIT RESULTS ===");
        $display("Total checks:       %0d", scoreboard.num_checked);
        $display("Functional checks:  %0d", scoreboard.num_functional_checks);
        $display("Invariant checks:   %0d", scoreboard.num_invariant_checks);
        $display("Mismatches:         %0d", scoreboard.mismatch_count);

        if (!has_failures() && scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
    endtask

endclass
