class control_env;

    virtual control_if vif;

    control_driver     driver;
    control_monitor    monitor;
    control_scoreboard scoreboard;

    mailbox #(control_txn) drv_mbx;
    mailbox #(control_obs) mon_mbx;

    int default_timeout_cycles;
    int num_txns_sent;

    function new(virtual control_if vif);
        this.vif = vif;

        drv_mbx = new();
        mon_mbx = new();

        driver     = new(vif, drv_mbx);
        monitor    = new(vif, mon_mbx);
        scoreboard = new(mon_mbx);

        default_timeout_cycles = 1000;
        num_txns_sent = 0;
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

    task wait_until_checked(int check_count, int timeout_cycles = -1);
        int target_checks;

        if (timeout_cycles < 0)
            timeout_cycles = default_timeout_cycles;

        target_checks = check_count;

        fork
            begin
                wait (scoreboard.num_checked >= target_checks);
            end

            begin
                repeat (timeout_cycles)
                    @(posedge vif.clk);

                if (scoreboard.num_checked < target_checks) begin
                    $fatal(1,
                           "Timeout waiting for %0d scoreboard checks (checked=%0d, sent=%0d, mismatches=%0d)",
                           target_checks, scoreboard.num_checked, num_txns_sent,
                           scoreboard.mismatch_count);
                end
            end
        join_any
        disable fork;
    endtask

    task wait_for_idle(int timeout_cycles = -1);
        if (num_txns_sent == 0) begin
            $fatal(1, "wait_for_idle() called before any transactions were sent");
        end

        wait_until_checked(num_txns_sent, timeout_cycles);
    endtask

    task wait_for_completion(int timeout_cycles = -1);
        wait_for_idle(timeout_cycles);
    endtask

    task report_results();
        $display("Total checks: %0d", scoreboard.num_checked);
        $display("Functional checks: %0d", scoreboard.num_functional_checks);
        $display("Invariant checks: %0d", scoreboard.num_invariant_checks);
        $display("Mismatches: %0d", scoreboard.mismatch_count);

        if (!has_failures() && scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAIL");
    endtask

endclass
