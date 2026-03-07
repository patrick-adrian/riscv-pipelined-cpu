class fetch_driver;

    virtual fetch_if vif;
    mailbox #(fetch_txn) mbx;

    function new(virtual fetch_if vif,
                 mailbox #(fetch_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        fetch_txn txn;

        forever begin
            mbx.get(txn);

            @(posedge vif.clk);

            vif.pc_src         <= txn.pc_src;
            vif.stall          <= txn.stall;
            vif.pc_target_ex   <= txn.pc_target_ex;
            vif.pc_plus4_ex    <= txn.pc_plus4_ex;
            vif.pred_pc_target <= txn.pred_pc_target;

            txn.display();
        end
    endtask

endclass