class decode_slice_random_test extends decode_slice_base_test;

    int num_txns = 50;

    function new(virtual decode_slice_if vif, decode_slice_env env);
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
            seed = 32'hDEC0DE01;
        end

        // Seed this process' random stream so object.randomize() uses the
        // reported seed and regressions can reproduce any failure.
        process::self().srandom(seed);

        if (has_seed) begin
            $display("Using constrained-random SEED=%0d (from plusarg)", seed);
        end else begin
            $display("Using constrained-random SEED=%0d (default, no SEED plusarg provided)", seed);
        end

        apply_reset();

        for (int i = 0; i < num_txns; i++) begin
            automatic decode_slice_txn t = new();

            assert(t.randomize() with {
                stall dist {1'b0 := 70, 1'b1 := 30};
                flush dist {1'b0 := 75, 1'b1 := 25};
            });

            // Mirror fetch_random_test by toggling reset only between already
            // observed transactions so mid-stream reset behavior is explicit.
            if ($urandom_range(0, 100) < 30) begin
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
