class fetch_driver;

    virtual fetch_if vif;
    mailbox #(fetch_txn) mbx;
    mailbox #(int)       drv_done_mbx;
    int num_sent = 0;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_txn) mbx,
                 mailbox #(int)       drv_done_mbx);
        this.vif = vif;
        this.mbx = mbx;
        this.drv_done_mbx = drv_done_mbx;
    endfunction

    task run();
        fetch_txn txn;

        forever begin
            mbx.get(txn);

            // Drive control signals on the negative edge so they are stable
            // before the next positive edge that clocks the DUT.
            @(negedge vif.clk);

            vif.pc_src         <= txn.pc_src;
            vif.stall          <= txn.stall;
            vif.pc_target_ex   <= txn.pc_target_ex;
            vif.pc_plus4_ex    <= txn.pc_plus4_ex;
            vif.pred_pc_target <= txn.pred_pc_target;

            // Tell the monitor a transaction's inputs have been applied.
            drv_done_mbx.put(txn.id);

            txn.display(vif.cycle);
            num_sent++;
        end
    endtask

endclass

