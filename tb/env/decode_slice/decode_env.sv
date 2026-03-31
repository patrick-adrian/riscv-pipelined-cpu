class ds_env;

    virtual ds_if vif;

    ds_driver     driver;
    ds_monitor    monitor;
    ds_scoreboard scoreboard;

    mailbox #(ds_txn) drv_mbx;
    mailbox #(ds_txn) scb_drv_mbx;
    mailbox #(ds_obs) mon_mbx;

    int txn_id = 0;
    int num_txns_sent = 0;
    int default_timeout_cycles = 1000;

    function new(virtual ds_if vif);
        this.vif = vif;

        drv_mbx     = new();
        scb_drv_mbx = new();
        mon_mbx     = new();

        driver     = new(vif, drv_mbx);
        monitor    = new(vif, mon_mbx);
        scoreboard = new(scb_drv_mbx, mon_mbx);
    endfunction

    task run();
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none
    endtask

    task put_txn(ds_txn txn);
        txn.id = txn_id++;
        drv_mbx.put(txn);
        scb_drv_mbx.put(txn);
        num_txns_sent++;
    endtask

    function bit has_failures();
        return scoreboard.mismatch_count != 0;
    endfunction

    task wait_for_completion(int timeout_cycles = -1);
        int waited = 0;
        if (timeout_cycles < 0) timeout_cycles = default_timeout_cycles;

        if (num_txns_sent == 0)
            $fatal(1, "wait_for_completion() called before any transactions sent");

        while (scoreboard.num_checked < num_txns_sent) begin
            @(posedge vif.clk);
            waited++;
            if (waited >= timeout_cycles)
                $fatal(1, "Timeout: checked=%0d sent=%0d mismatches=%0d",
                       scoreboard.num_checked, num_txns_sent, scoreboard.mismatch_count);
        end
    endtask

    task report_results();
        $display("=== DECODE SLICE RESULTS ===");
        $display("Total checks:  %0d", scoreboard.num_checked);
        $display("Mismatches:    %0d", scoreboard.mismatch_count);

        if (!has_failures() && scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
    endtask

endclass
