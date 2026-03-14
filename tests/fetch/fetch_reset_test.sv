`timescale 1ns/1ps

// Reset test: assert reset, release, then one sequential transaction; verify via scoreboard.
module fetch_reset_test;

    fetch_tb tb();
    fetch_env env;

    initial begin
        tb.vif.reset = 1;
        repeat (3) @(posedge tb.clk);
        tb.vif.reset = 0;
        repeat (1) @(posedge tb.clk);

        env = new(tb.vif);
        env.run();

        // One transaction: sequential (pc_src=0), no stall
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

        #200 $finish;
    end

endmodule
