class decode_slice_stall_test extends decode_slice_base_test;

    function new(virtual decode_slice_if vif, decode_slice_env env);
        super.new(vif, env);
    endfunction

    virtual task run();
        apply_reset();

        // Load a known instruction, then prove a stall holds it even while the
        // TB presents different instruction and PC values.
        send_txn(1'b0, 1'b0, 32'h02A00093, 32'h0000_0000); // ADDI x1, x0, 42
        send_txn(1'b1, 1'b0, 32'h0080A103, 32'h0000_0004); // LW x2, 8(x1)
        send_txn(1'b0, 1'b0, 32'h0020A823, 32'h0000_0008); // SW x2, 16(x1)
        send_txn(1'b1, 1'b0, 32'h00208463, 32'h0000_000C); // BEQ x1, x2, 8
        send_txn(1'b0, 1'b0, 32'hDEADB1B7, 32'h0000_0010); // LUI x3, 0xDEADB

        report_and_finish();
    endtask

endclass
