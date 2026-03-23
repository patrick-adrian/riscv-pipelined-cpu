class fetch_reset_test extends fetch_base_test;

    function new(virtual fetch_if vif, fetch_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // TXN 0: sequential (pc_src=0), no stall
        begin
            fetch_txn t;
            t = new();
            t.pc_src         = 0;
            t.stall          = 0;
            t.pc_target_ex   = 32'h0;
            t.pc_plus4_ex    = 32'h0;
            t.pred_pc_target = 32'h0;
            env.put_txn(t);
        end

        // TXN 1: straight-line from PC=0 -> 4
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0004;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // Reset stays on after two txns
        wait (env.scoreboard.num_checked == 2);
        @(posedge vif.clk);
        vif.reset = 1;

        // TXN 2: straight-line 4 -> 8
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0008;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 3: predicted branch to 0x20
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd1;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0020;
            env.put_txn(t);
        end

        // Recovery test
        wait (env.scoreboard.num_checked == 4);
        @(posedge vif.clk);
        vif.reset = 0;

        // TXN 4: sequential (pc_src=0), no stall
        begin
            fetch_txn t;
            t = new();
            t.pc_src         = 0;
            t.stall          = 0;
            t.pc_target_ex   = 32'h0;
            t.pc_plus4_ex    = 32'h0;
            t.pred_pc_target = 32'h0;
            env.put_txn(t);
        end

        // TXN 5: straight-line from PC=0 -> 4
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0004;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 6: straight-line 4 -> 8
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0008;
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        // TXN 7: predicted branch to 0x20
        begin
            fetch_txn t = new();
            t.pc_src         = 2'd1;
            t.stall          = 1'b0;
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = 32'h0000_0000;
            t.pred_pc_target = 32'h0000_0020;
            env.put_txn(t);
        end

        report_and_finish();
    endtask

endclass
