`timescale 1ns/1ps

// Smoke test: instantiate fetch harness and env, drive 20 random transactions.
module fetch_smoke_test;

    fetch_tb tb();
    fetch_env env;

    initial begin
        tb.vif.reset = 1;
        repeat (2) @(posedge tb.clk);
        tb.vif.reset = 0;

        env = new(tb.vif);
        env.run();

        for (int i = 0; i < 20; i++) begin
            automatic fetch_txn t = new();
            assert(t.randomize());
            env.put_txn(t);
        end

        #500 $finish;
    end

endmodule
