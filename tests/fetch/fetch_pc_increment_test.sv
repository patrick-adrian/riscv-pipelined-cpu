`timescale 1ns/1ps

// PC increment test: drive a sequence of pure sequential instructions
// (pc_src=0, no stalls) and let the scoreboard verify PC += 4 each cycle.
module fetch_pc_increment_test;

    fetch_tb tb();
    fetch_env env;

    int num_txns = 16;

    initial begin
        // Apply reset
        tb.vif.reset = 1;
        repeat (3) @(posedge tb.clk);
        tb.vif.reset = 0;
        repeat (1) @(posedge tb.clk);

        // Start environment
        env = new(tb.vif);
        env.run();

        // Drive a straight-line sequence
        for (int i = 0; i < num_txns; i++) begin
            fetch_txn t = new();
            t.pc_src         = 2'd0;
            t.stall          = 1'b0;
            // Execute stage values are not used for straight-line,
            // but keep them aligned/valid.
            t.pc_target_ex   = 32'h0000_0000;
            t.pc_plus4_ex    = (32'(i+1) * 32'd4);
            t.pred_pc_target = 32'h0000_0000;
            env.put_txn(t);
        end

        #1000 $finish;
    end

endmodule

