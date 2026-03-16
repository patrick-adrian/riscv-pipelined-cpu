`timescale 1ns/1ps

// Random test: long, purely randomized stream of fetch_txn to stress the stage.
module fetch_random_test;

    fetch_tb tb();
    fetch_env env;

    int num_txns = 200;

    initial begin
        // Apply reset
        tb.vif.reset = 1;
        repeat (3) @(posedge tb.clk);
        tb.vif.reset = 0;
        repeat (1) @(posedge tb.clk);

        // Start environment
        env = new(tb.vif);
        env.run();

        // Drive a randomized stream
        for (int i = 0; i < num_txns; i++) begin
            automatic fetch_txn t = new();
            assert(t.randomize());
            env.put_txn(t);
        end

        #2000 $finish;
    end

endmodule

