`timescale 1ns/1ps

// Random test: long, purely randomized stream of fetch_txn to stress the stage.
module fetch_random_test;

    fetch_tb tb();
    fetch_env env;

    int num_txns = 50;

    initial begin
        int seed;
        bit has_seed;

        // Determine the seed:
        //  - If SEED plusarg is provided, use that.
        //  - Otherwise use a fixed default so runs are still reproducible.
        has_seed = $value$plusargs("SEED=%d", seed);
        if (!has_seed) begin
            seed = 32'hC0FFEE01;
        end

        // Seed this process' random stream so that object.randomize()
        // uses the reported seed.
        process::self().srandom(seed);

        // Always report the effective seed so regressions can reproduce runs.
        if (has_seed) begin
            $display("Using constrained-random SEED=%0d (from plusarg)", seed);
        end else begin
            $display("Using constrained-random SEED=%0d (default, no SEED plusarg provided)", seed);
        end

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

        env.wait_for_completion();
        $display("Total checks: %0d", env.scoreboard.num_checked);
        $display("Mismatches: %0d", env.scoreboard.mismatch_count);
        if (env.scoreboard.mismatch_count == 0 &&
            env.scoreboard.num_checked > 0)
            $display("TEST PASSED");
        else
            $display("TEST FAIL");
        $finish;
    end

endmodule

