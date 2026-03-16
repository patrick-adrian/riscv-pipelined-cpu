`timescale 1ns/1ps

// Branch test: exercise all branch/redirection sources.
//  - predicted branch (pc_src=1)
//  - execute plus4 redirect (pc_src=2)
//  - execute absolute target redirect (pc_src=3)
//  - mix in a few straight-line and stall cycles
module fetch_branch_test;

    fetch_tb tb();
    fetch_env env;

    initial begin
        // Apply reset
        tb.vif.reset = 1;
        repeat (3) @(posedge tb.clk);
        tb.vif.reset = 0;
        repeat (1) @(posedge tb.clk);

        // Start environment
        env = new(tb.vif);
        env.run();

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

        #1000 $finish;
    end

endmodule

