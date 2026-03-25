class fetch_env;

    virtual fetch_if vif;

    fetch_driver     driver;
    fetch_monitor    monitor;
    fetch_scoreboard scoreboard;

    mailbox #(fetch_txn) drv_mbx;
    mailbox #(fetch_txn) scb_drv_mbx;
    mailbox #(fetch_obs) mon_mbx;

    int default_timeout_cycles;
    int txn_id;
    int num_txns_sent;

    function new(virtual fetch_if vif);
        this.vif = vif;

        drv_mbx     = new();
        scb_drv_mbx = new();
        mon_mbx     = new();

        driver     = new(vif, drv_mbx);
        monitor    = new(vif, mon_mbx);
        scoreboard = new(vif, scb_drv_mbx, mon_mbx);

        default_timeout_cycles = 1000;
        txn_id       = 0;
        num_txns_sent = 0;
    endfunction

    task run();
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none
    endtask

    // Test injects transactions via put_txn (tests/fetch/*.sv).
    task put_txn(fetch_txn txn);
        txn.id = txn_id++;
        drv_mbx.put(txn);
        scb_drv_mbx.put(txn);
        num_txns_sent++;
    endtask

    function bit has_failures();
        return scoreboard.mismatch_count != 0;
    endfunction

    task wait_until_checked(int check_count, int timeout_cycles = -1);
        int waited_cycles = 0;

        if (timeout_cycles < 0)
            timeout_cycles = default_timeout_cycles;

        while (scoreboard.num_checked < check_count) begin
            @(posedge vif.clk);
            waited_cycles++;

            if (waited_cycles >= timeout_cycles) begin
                $fatal(1,
                       "Timeout waiting for %0d scoreboard checks (checked=%0d, sent=%0d, mismatches=%0d)",
                       check_count, scoreboard.num_checked, num_txns_sent,
                       scoreboard.mismatch_count);
            end
        end
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
        $display("Mismatches: %0d", scoreboard.mismatch_count);

        if (!has_failures() && scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAIL");
    endtask

endclass

