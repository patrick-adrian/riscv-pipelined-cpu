`include "control_macros.sv"

class decode_imm_random_test extends decode_base_test;

    int num_txns = 100;

    function new(virtual decode_if vif, decode_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        int seed;
        bit has_seed;

        // Determine the seed.
        has_seed = $value$plusargs("SEED=%d", seed);
        if (!has_seed) begin
            seed = 32'hC0FFEE01;
        end

        process::self().srandom(seed);

        if (has_seed) begin
            $display("Using constrained-random SEED=%0d (from plusarg)", seed);
        end else begin
            $display("Using constrained-random SEED=%0d (default, no SEED plusarg provided)", seed);
        end

        // Create a randomized stream of decode_txn items.
        for (int i = 0; i < num_txns; i++) begin
            automatic decode_txn t = new();
            assert(t.randomize());

            // Keep imm_src in the supported set for better coverage.
            t.imm_src_de_i = $urandom_range(0, 5);

            // Control randomization.
            if (i < 2) begin
                t.reset = 1'b1;
                t.flush = 1'b0;
                t.stall = 1'b0;
            end else begin
                t.reset = ($urandom_range(0, 99) < 5);
                t.flush = (!t.reset) && ($urandom_range(0, 99) < 5);
                t.stall = (!t.reset) && (!t.flush) && ($urandom_range(0, 99) < 20);
            end

            env.put_txn(t);
        end

        report_and_finish();
    endtask

endclass

