class fetch_env;

    virtual fetch_if vif;

    fetch_driver     driver;
    fetch_monitor    monitor;
    fetch_scoreboard scoreboard;

    mailbox #(fetch_txn)    drv_mbx;
    mailbox #(fetch_txn)    scb_drv_mbx;
    mailbox #(logic [31:0]) mon_mbx;

    int txn_id;

    function new(virtual fetch_if vif);
        this.vif = vif;

        drv_mbx     = new();
        scb_drv_mbx = new();
        mon_mbx     = new();

        driver     = new(vif, drv_mbx);
        monitor    = new(vif, mon_mbx);
        scoreboard = new(vif, scb_drv_mbx, mon_mbx);

        txn_id = 0;
    endfunction

    task run();
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none

        // Generate transactions
        repeat (20) begin
            fetch_txn txn = new();
            txn.id = txn_id++;

            assert(txn.randomize());
            drv_mbx.put(txn);
            scb_drv_mbx.put(txn);
        end
    endtask

endclass

