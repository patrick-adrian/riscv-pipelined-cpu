class fetch_branch_test extends fetch_base_test;

    function new(virtual fetch_if vif, fetch_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // TXN 0: straight-line from 0 -> 4
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0004;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 1: predicted branch to 0x40
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd1;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0040;
            env.put_txn(t);
        end

        // TXN 2: execute plus4 redirect (fall-through from 0x40 -> 0x44)
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd2;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0044;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 3: execute absolute target redirect to 0x100
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd3;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0100;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 4: stall, PC should hold at 0x100
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0; // don't care due to stall
            t.stall          = 1'b1;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 5: straight-line from 0x100 -> 0x104
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0104;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        report_and_finish();
    endtask

endclass

