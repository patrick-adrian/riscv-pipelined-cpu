class fetch_random_seq extends fetch_base_seq;

    int num_txns;

    `uvm_object_utils(fetch_random_seq)

    function new(string name = "fetch_random_seq");
        super.new(name);
        num_txns = 50;
    endfunction

    task body();
        fetch_txn t;
        int seed;
        bit has_seed;

        has_seed = $value$plusargs("SEED=%d", seed);
        if (!has_seed) begin
            seed = 32'hC0FFEE01;
        end

        process::self().srandom(seed);

        if (has_seed) begin
            `uvm_info("FETCH/RAND",
                      $sformatf("Using constrained-random SEED=%0d (from plusarg)", seed),
                      UVM_LOW)
        end else begin
            `uvm_info("FETCH/RAND",
                      $sformatf("Using constrained-random SEED=%0d (default, no SEED plusarg provided)", seed),
                      UVM_LOW)
        end

        apply_reset();

        for (int i = 0; i < num_txns; i++) begin
            if ($urandom_range(0, 100) < 30) begin
                if (reset_is_asserted()) begin
                    deassert_reset();
                    wait_cycles(1);
                end else begin
                    assert_reset();
                end
            end

            t = fetch_txn::type_id::create($sformatf("txn%0d", i));
            start_item(t);
            if (!t.randomize()) begin
                `uvm_fatal("FETCH/RAND", $sformatf("randomize failed for transaction %0d", i))
            end
            finish_item(t);
        end

        if (reset_is_asserted()) begin
            deassert_reset();
            wait_cycles(1);
        end
    endtask

endclass
