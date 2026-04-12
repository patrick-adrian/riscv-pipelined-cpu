class fetch_decode_env;

    virtual fetch_decode_control_if vif;

    fetch_decode_driver    driver;
    integrated_monitor     monitor;
    integrated_scoreboard  scoreboard;

    mailbox #(fetch_decode_txn) drv_mbx;
    mailbox #(integrated_obs)   mon_mbx;

    int default_timeout_cycles;
    int num_txns_sent;

    function new(virtual fetch_decode_control_if vif);
        this.vif = vif;

        drv_mbx    = new();
        mon_mbx    = new();
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

    task put_txn(fetch_decode_txn txn);
        drv_mbx.put(txn);
        num_txns_sent++;
    endtask

    function bit has_failures();
        return scoreboard.mismatch_count != 0;
    endfunction

    task wait_until_checked(int check_count, int timeout_cycles = -1);
        if (timeout_cycles < 0)
            timeout_cycles = default_timeout_cycles;

        fork
            begin
                wait (scoreboard.num_checked >= check_count);
            end

            begin
                repeat (timeout_cycles)
                    @(posedge vif.clk);

                if (scoreboard.num_checked < check_count) begin
                    $fatal(1,
                           "Timeout waiting for %0d integrated scoreboard checks (checked=%0d mismatches=%0d txns=%0d)",
                           check_count, scoreboard.num_checked, scoreboard.mismatch_count, num_txns_sent);
                end
            end
        join_any
        disable fork;
    endtask

    task report_results();
        $display("Total checks: %0d", scoreboard.num_checked);
        $display("Fetch checks: %0d", scoreboard.num_fetch_checks);
        $display("Decode checks: %0d", scoreboard.num_decode_checks);
        $display("Control checks: %0d", scoreboard.num_control_checks);
        $display("Mismatches: %0d", scoreboard.mismatch_count);

        if (!has_failures() && scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAIL");
    endtask

endclass
