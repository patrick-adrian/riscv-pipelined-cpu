class fetch_driver;

    virtual fetch_if vif;
    mailbox #(fetch_txn) mbx;
    int num_sent = 0;

    function new(virtual fetch_if vif,
                mailbox #(fetch_txn) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction

    task run();
        fetch_txn txn;
        bit       have_txn;
        int       cycle_count = 0;
        time      log_time;

        forever begin
            @(posedge vif.clk);
            cycle_count++;

            have_txn = mbx.try_get(txn);
            if (!have_txn) begin
                vif.tb_valid        <= 1'b0;
                vif.pc_src          <= 2'd0;
                vif.stall           <= 1'b1;
                vif.pc_target_ex    <= 32'h0;
                vif.pc_plus4_ex     <= 32'h0;
                vif.pred_pc_target  <= 32'h0;
                continue;
            end

            vif.tb_valid        <= 1'b1;
            vif.pc_src          <= txn.pc_src;
            vif.stall           <= txn.stall;
            vif.pc_target_ex    <= txn.pc_target_ex;
            vif.pc_plus4_ex     <= txn.pc_plus4_ex;
            vif.pred_pc_target  <= txn.pred_pc_target;

            log_time = $time;
            #2ps;
            txn.display(cycle_count, log_time);
            num_sent++;
        end
    endtask

endclass

