class fetch_pc_increment_test extends fetch_base_test;

    int num_txns = 16;

    function new(virtual fetch_if vif, fetch_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

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

        report_and_finish();
    endtask

endclass

