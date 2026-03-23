class fetch_smoke_test extends fetch_base_test;

    function new(virtual fetch_if vif, fetch_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // TXN 0: straight-line from PC=0 -> 4
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0004;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 1: straight-line 4 -> 8
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0008;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 2: predicted branch to 0x20
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd1;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0020;
            env.put_txn(t);
        end

        // TXN 3: execute plus4 redirect (e.g. correct fall-through)
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd2;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0024;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 4: execute absolute target redirect with stall=1 (PC should hold)
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd3;
            t.stall          = 1'b1;
            t.pc_target_ex   = 32'h0000_0040;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        report_and_finish();
    endtask

endclass
