class decode_slice_flush_test extends decode_slice_base_test;

    function new(virtual decode_slice_if vif, decode_slice_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // Flush should clear the pipeline register even if the TB presents a
        // valid instruction, and the stage should recover on the next cycle.
        send_txn(1'b0, 1'b0, 32'h02A00093, 32'h0000_0000); // ADDI x1, x0, 42
        send_txn(1'b0, 1'b1, 32'h0080A103, 32'h0000_0004); // flush this cycle
        send_txn(1'b0, 1'b0, 32'h0020A823, 32'h0000_0008); // recover with store
        send_txn(1'b0, 1'b1, 32'h00208463, 32'h0000_000C); // flush again
        send_txn(1'b0, 1'b0, 32'h1000026F, 32'h0000_0010); // recover with JAL

        report_and_finish();
    endtask

endclass
