class fetch_random_test extends fetch_base_test;

    int num_txns = 50;

    function new(virtual fetch_if vif, fetch_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
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

        apply_reset();

        // Drive a randomized stream
        for (int i = 0; i < num_txns; i++) begin
            automatic fetch_txn t = new();
            int pcnt = 0;

            assert(t.randomize());
            
            if (vif.reset == 1'b0) begin
                pcnt = 30;
            end else begin
                pcnt = 30;
            end
            if($urandom_range(0, 100) < pcnt) begin
                env.wait_until_checked(i); 
                if (vif.reset == 1'b0) begin
                    assert_reset();
                end else begin
                    deassert_reset();
                end
            end
            env.put_txn(t);
        end

        report_and_finish();
    endtask

endclass

