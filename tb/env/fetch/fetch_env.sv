class fetch_env;

    virtual fetch_if vif;

    fetch_driver     driver;
    fetch_monitor    monitor;
    fetch_scoreboard scoreboard;

    mailbox #(fetch_txn)    drv_mbx;
    mailbox #(fetch_txn)    scb_drv_mbx;
    mailbox #(logic [31:0]) mon_mbx;

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
    
    task wait_for_completion();
        // Only wait once the test has actually sent at least one transaction.
        wait (num_txns_sent > 0 && scoreboard.num_checked == num_txns_sent);
    endtask

endclass

