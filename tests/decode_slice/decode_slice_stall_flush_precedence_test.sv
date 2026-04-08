class decode_slice_stall_flush_precedence_test extends decode_slice_base_test;

    function new(virtual decode_slice_if vif, decode_slice_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // First prove a plain stall holds state.
        send_txn(1'b0, 1'b0, 32'h02A00093, 32'h0000_0000); // ADDI x1, x0, 42
        send_txn(1'b1, 1'b0, 32'h0080A103, 32'h0000_0004); // stall only

        // Then prove flush wins when both controls are asserted together.
        send_txn(1'b1, 1'b1, 32'h0020A823, 32'h0000_0008); // stall + flush
        send_txn(1'b0, 1'b1, 32'h00208463, 32'h0000_000C); // flush only
        send_txn(1'b1, 1'b1, 32'hDEADB1B7, 32'h0000_0010); // stall + flush again

        // Recovery after the combined control case should still work normally.
        send_txn(1'b0, 1'b0, 32'h1000026F, 32'h0000_0014); // JAL x4, 256
        send_txn(1'b0, 1'b0, 32'h002083B3, 32'h0000_0018); // ADD x7, x1, x2

        report_and_finish();
    endtask

endclass
